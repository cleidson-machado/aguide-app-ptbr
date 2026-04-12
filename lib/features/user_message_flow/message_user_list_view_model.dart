import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_message_flow/models/message_user_data.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// Sorting criteria for message user list
enum MessageUserSortCriteria {
  alphabeticalAZ,
  alphabeticalZA,
}

/// ViewModel específico para lista de usuários na feature user_message_flow
/// 
/// **Princípio DDD:** Este ViewModel é isolado da feature 'user' core.
/// Combina dados de UserModel (GET /users) + UserDetailsModel (GET /users/{id}/details)
/// para fornecer role designation sem modificar feature core.
/// 
/// Estratégia de carregamento:
/// 1. Carrega todos os usuários com getAll() → List<UserModel>
/// 2. Para cada usuário, carrega detalhes com getUserDetails(id) → UserDetailsModel
/// 3. Combina em List<MessageUserData> usando factory pattern
class MessageUserListViewModel extends ChangeNotifier {
  MessageUserListViewModel({
    required UserRepositoryInterface repository,
  }) : _repository = repository;

  final UserRepositoryInterface _repository;

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

      _users = enrichedUsers;
      _applyCurrentSort();
      _log('loadUsers success count=${_users.length} with role designation');
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
