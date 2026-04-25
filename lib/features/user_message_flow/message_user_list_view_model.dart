import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';
import 'package:portugal_guide/features/user_message_flow/models/user_message_contact_model.dart';
import 'package:portugal_guide/features/user_message_flow/user_message_flow_repository_interface.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// Sorting criteria for message user list
enum MessageUserSortCriteria {
  alphabeticalAZ,
  alphabeticalZA,
  recentMessagesFirst,
}

/// ViewModel específico para lista de usuários na feature user_message_flow
/// 
/// **Princípio DDD:** Este ViewModel é isolado da feature 'user' core.
/// Combina dados de UserModel (GET /users) + UserDetailsModel (GET /users/{id}/details)
/// + ConversationSummary (GET /conversations) para fornecer role designation
/// e timestamp da última mensagem sem modificar feature core.
class MessageUserListViewModel extends ChangeNotifier {
  MessageUserListViewModel({
    required UserRepositoryInterface repository,
    required UserMessageFlowRepositoryInterface messageRepository,
  })  : _repository = repository,
        _messageRepository = messageRepository;

  final UserRepositoryInterface _repository;
  final UserMessageFlowRepositoryInterface _messageRepository;

  List<MessageUserData> _users = [];
  bool _isLoading = false;
  String? _error;
  MessageUserSortCriteria _currentSort = MessageUserSortCriteria.alphabeticalAZ;

  List<MessageUserData> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MessageUserSortCriteria get currentSort => _currentSort;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('👥💬 [MessageUserListViewModel] $message');
    }
  }

  /// Load all users with role designation from API
  /// 
  /// Estratégia: GET /users + GET /users/{id}/details para cada usuário
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    _log('loadUsers start');
    notifyListeners();

    try {
      // Step 1: Carregar lista básica de usuários (GET /users)
      final basicUsers = await _repository.getAll();
      _log('Loaded ${basicUsers.length} basic users');

      // Step 2: Carregar detalhes para cada usuário (GET /users/{id}/details)
      final List<MessageUserData> enrichedUsers = [];
      
      for (final user in basicUsers) {
        try {
          final details = await _repository.getUserDetails(user.id);
          final messageUserData = MessageUserData.fromUserAndDetails(user, details);
          enrichedUsers.add(messageUserData);
          
          if (kDebugMode) {
            debugPrint('   ✅ Enriched user: ${messageUserData.fullName} → ${messageUserData.roleLabel}');
          }
        } catch (e) {
          // Se falhar ao carregar detalhes de um usuário, loga mas continua
          _log('⚠️  Failed to load details for user ${user.id}: $e');
          // Criar MessageUserData sem detalhes YouTube (será CONSUMIDOR)
          enrichedUsers.add(MessageUserData(
            id: user.id,
            name: user.name,
            surname: user.surname,
            email: user.email,
            fullName: '${user.name} ${user.surname}',
            youtubeUserId: null,
            youtubeChannelId: null,
          ));
        }
      }

      // Filtrar o próprio usuário da lista (não pode enviar mensagem para si mesmo)
      final currentUserId = injector<AuthTokenManager>().getUserId();
      _users = enrichedUsers.where((user) => user.id != currentUserId).toList();

      // Step 3: Enriquecer com metadata de conversas existentes (lastMessageAt, unreadCount)
      await _enrichWithConversationMetadata(currentUserId);

      _applyCurrentSort();
      _log('loadUsers success count=${_users.length} with role designation (currentUserId=$currentUserId filtered out)');
    } catch (e) {
      _users = [];
      _error = _mapExceptionToMessage(e);
      _log('loadUsers error=$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user list (pull-to-refresh)
  Future<void> refreshUsers() async {
    _log('refreshUsers start');
    try {
      // Mesma lógica de loadUsers mas sem mostrar loading spinner
      final basicUsers = await _repository.getAll();
      _log('Refreshed ${basicUsers.length} basic users');

      final List<MessageUserData> enrichedUsers = [];
      
      for (final user in basicUsers) {
        try {
          final details = await _repository.getUserDetails(user.id);
          final messageUserData = MessageUserData.fromUserAndDetails(user, details);
          enrichedUsers.add(messageUserData);
        } catch (e) {
          _log('⚠️  Failed to refresh details for user ${user.id}: $e');
          enrichedUsers.add(MessageUserData(
            id: user.id,
            name: user.name,
            surname: user.surname,
            email: user.email,
            fullName: '${user.name} ${user.surname}',
            youtubeUserId: null,
            youtubeChannelId: null,
          ));
        }
      }

      _users = enrichedUsers;

      // Re-aplicar enrichment de conversas no refresh
      final currentUserId = injector<AuthTokenManager>().getUserId();
      _users = _users.where((user) => user.id != currentUserId).toList();
      await _enrichWithConversationMetadata(currentUserId);

      _applyCurrentSort();
      _error = null;
      _log('refreshUsers success count=${_users.length}');
    } catch (e) {
      _error = _mapExceptionToMessage(e);
      _log('refreshUsers error=$_error');
    } finally {
      notifyListeners();
    }
  }

  /// Sort users by specified criteria
  void sortUsers(MessageUserSortCriteria criteria) {
    _log('sortUsers criteria=$criteria');
    _currentSort = criteria;
    _applyCurrentSort();
    notifyListeners();
  }

  /// Apply current sort criteria to users list
  void _applyCurrentSort() {
    switch (_currentSort) {
      case MessageUserSortCriteria.alphabeticalAZ:
        _users.sort((a, b) {
          final nameA = a.fullName.toLowerCase();
          final nameB = b.fullName.toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
      case MessageUserSortCriteria.alphabeticalZA:
        _users.sort((a, b) {
          final nameA = a.fullName.toLowerCase();
          final nameB = b.fullName.toLowerCase();
          return nameB.compareTo(nameA);
        });
        break;
      case MessageUserSortCriteria.recentMessagesFirst:
        _users.sort((a, b) {
          // Users with messages first (DESC by lastMessageAt), then users without messages alphabetically
          final aTs = a.lastMessageAt;
          final bTs = b.lastMessageAt;
          if (aTs == null && bTs == null) {
            return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          }
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
        break;
    }
  }

  /// Enriquece a lista de usuários com metadata de conversas DIRECT existentes
  ///
  /// Estratégia (com endpoints atuais):
  /// 1. GET /conversations → lista de conversas (sem otherUserId em DIRECT)
  /// 2. Para cada conversa DIRECT, GET /conversations/{id} → participants[]
  /// 3. Mapeia conv.lastMessageAt/unreadCount → MessageUserData via otherUserId
  ///
  /// Não-crítico: falhas são logadas mas não bloqueiam a tela.
  Future<void> _enrichWithConversationMetadata(String? currentUserId) async {
    try {
      _log('Loading conversations metadata for ${_users.length} users');
      final conversations = await _messageRepository.getConversations();
      final directConversations =
          conversations.where((c) => c.type == 'DIRECT').toList();
      _log('Found ${directConversations.length} DIRECT conversations');

      // Mapeia otherUserId → conversation summary
      final Map<String, UserMessageContactModel> userIdToConversation = {};

      for (final conv in directConversations) {
        try {
          // Precisamos buscar detalhes para descobrir otherUserId (não vem na lista)
          final details = await _messageRepository.getConversationDetails(conv.id);
          // getConversationDetails já preenche contactName com nome do outro participante,
          // mas não expõe otherUserId. Vamos buscar diretamente via raw match na lista de users.
          // Como contactName vem do outro participante, usamos para matchar.
          final match = _users.firstWhere(
            (u) => u.fullName.toLowerCase() == details.contactName.toLowerCase(),
            orElse: () => const MessageUserData(
              id: '',
              name: '',
              surname: '',
              email: '',
              fullName: '',
            ),
          );
          if (match.id.isNotEmpty) {
            userIdToConversation[match.id] = conv;
          }
        } catch (e) {
          _log('⚠️  Failed to load conversation details for ${conv.id}: $e');
        }
      }

      // Aplica metadata aos usuários
      _users = _users.map((user) {
        final conv = userIdToConversation[user.id];
        if (conv == null) return user;
        return user.copyWith(
          conversationId: conv.id,
          lastMessageAt: conv.lastMessageAt,
          lastMessagePreview: conv.lastMessage,
          unreadCount: conv.unreadCount,
        );
      }).toList();

      _log('✅ Enriched ${userIdToConversation.length} users with conversation metadata');
    } catch (e) {
      // Não-crítico: lista de usuários ainda é exibida sem timestamps
      _log('⚠️  Failed to enrich with conversation metadata (non-critical): $e');
    }
  }

  /// Silent polling refresh - re-fetches ONLY conversation metadata
  /// (lastMessageAt, unreadCount, lastMessagePreview) without reloading
  /// the user list itself. Designed for auto-refresh timers.
  ///
  /// Behavior:
  /// - Does NOT set _isLoading (no UI flash)
  /// - Does NOT touch _error (preserves existing error state)
  /// - Only notifies listeners if conversation metadata actually changed
  /// - Errors are silently logged (non-critical)
  Future<void> silentRefreshConversations() async {
    if (_users.isEmpty) {
      _log('silentRefreshConversations skipped: empty user list');
      return;
    }

    try {
      _log('silentRefreshConversations start (${_users.length} users)');

      // Snapshot current metadata to detect changes
      final beforeSnapshot = {
        for (final u in _users)
          u.id: '${u.lastMessageAt?.millisecondsSinceEpoch}|${u.unreadCount}|${u.lastMessagePreview}'
      };

      final currentUserId = injector<AuthTokenManager>().getUserId();
      await _enrichWithConversationMetadata(currentUserId);

      // Detect if anything changed
      final hasChanges = _users.any((u) {
        final newKey = '${u.lastMessageAt?.millisecondsSinceEpoch}|${u.unreadCount}|${u.lastMessagePreview}';
        return beforeSnapshot[u.id] != newKey;
      });

      if (hasChanges) {
        _applyCurrentSort();
        _log('silentRefreshConversations: changes detected → notifying');
        notifyListeners();
      } else {
        _log('silentRefreshConversations: no changes');
      }
    } catch (e) {
      // Silent failure - polling errors must NOT bother the user
      _log('silentRefreshConversations: error (silent): $e');
    }
  }

  /// Map exceptions to user-friendly error messages
  String _mapExceptionToMessage(dynamic exception) {
    final errorString = exception.toString().toLowerCase();

    // Check for common HTTP status codes in exception message
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sessão expirada. Faça login novamente.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Você não tem permissão para acessar os usuários.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Recurso não encontrado.';
    }
    if (errorString.contains('500') ||
        errorString.contains('503') ||
        errorString.contains('server')) {
      return 'Erro no servidor. Tente novamente mais tarde.';
    }
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    // Fallback to generic error message
    return ErrorMessages.defaultMsnFailedToLoadData;
  }

  @override
  void dispose() {
    _log('dispose');
    super.dispose();
  }
}
