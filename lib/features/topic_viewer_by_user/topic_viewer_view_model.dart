import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';

class TopicViewerViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;
  final OwnershipRepositoryInterface _ownershipRepository;

  TopicViewerViewModel({
    UserRepositoryInterface? userRepository,
    OwnershipRepositoryInterface? ownershipRepository,
  })  : _userRepository = userRepository ?? injector<UserRepositoryInterface>(),
        _ownershipRepository = ownershipRepository ?? injector<OwnershipRepositoryInterface>();

  // ===== Estado de User Details =====
  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  // ===== Estado de Ownership (Conteúdos Verificados) =====
  List<OwnershipContentModel> _ownershipContents = [];
  bool _isLoadingOwnership = false;
  String? _ownershipError;

  // ===== Getters para User Details =====
  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;

  // ===== Getters para Ownership =====
  List<OwnershipContentModel> get ownershipContents => _ownershipContents;
  bool get isLoadingOwnership => _isLoadingOwnership;
  String? get ownershipError => _ownershipError;
  bool get hasOwnershipContents => _ownershipContents.isNotEmpty;

  /// Determina se o usuário é CRIADOR (Produtor de Conteúdo)
  /// 
  /// Lógica: Se ambos youtubeUserId E youtubeChannelId são não-nulos → CRIADOR
  /// Qualquer outra combinação → CONSUMIDOR
  bool get isContentCreator {
    if (_userDetails == null) {
      if (kDebugMode) {
        debugPrint('🔍 [TopicViewerVM] _userDetails é NULL → retornando FALSE (CONSUMIDOR)');
      }
      return false;
    }

    final hasYoutubeUserId = _userDetails!.youtubeUserId != null &&
        _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null &&
        _userDetails!.youtubeChannelId!.isNotEmpty;

    final isCriador = hasYoutubeUserId && hasYoutubeChannelId;

    if (kDebugMode) {
      debugPrint('🔍 [TopicViewerVM] Verificação:');
      debugPrint('   youtubeUserId: ${_userDetails!.youtubeUserId ?? "NULL"} → hasYoutubeUserId: $hasYoutubeUserId');
      debugPrint('   youtubeChannelId: ${_userDetails!.youtubeChannelId ?? "NULL"} → hasYoutubeChannelId: $hasYoutubeChannelId');
      debugPrint('   Resultado: ${isCriador ? "CRIADOR" : "CONSUMIDOR"}');
    }

    return isCriador;
  }

  /// Título dinâmico baseado no tipo de usuário
  /// - CRIADOR: "Meus Vídeos - Criados"
  /// - CONSUMIDOR: "Conteúdo que Já Assisti"
  String get dinamicTitle {
    final title = isContentCreator
        ? 'Meus Vídeos - Criados'
        : 'Conteúdo que Já Assisti';

    if (kDebugMode) {
      debugPrint('🏷️  [TopicViewerVM] dinamicTitle: "$title"');
    }

    return title;
  }

  /// Carrega detalhes do usuário para determinar se é CRIADOR ou CONSUMIDOR
  Future<void> loadUserDetails(String userId) async {
    _isLoadingUserDetails = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('════════════════════════════════════════════════════════════════');
        debugPrint('👤 CARREGANDO USER DETAILS - TopicViewerViewModel');
        debugPrint('════════════════════════════════════════════════════════════════');
        debugPrint('   🆔 UserId: $userId');
      }

      _userDetails = await _userRepository.getUserDetails(userId);

      if (kDebugMode) {
        debugPrint('   ✅ User details carregados com sucesso');
        debugPrint('   🎯 isContentCreator: $isContentCreator');
        debugPrint('────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      _userDetails = null;
      if (kDebugMode) {
        debugPrint('   ❌ Erro ao carregar user details: $e');
      }
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }

  /// Carrega conteúdos verificados (ownership) do usuário específico
  /// 
  /// Usa endpoint: GET /api/v1/ownership/user/{userId}/content
  /// Exibe "Meus Vídeos - CRIADOS" para CRIADORES
  /// Este método filtra conteúdos pela autoria reconhecida no banco de dados,
  /// não pelo JWT. Apenas conteúdos criados ou assignados ao usuário são retornados.
  Future<void> loadOwnershipContents(String userId) async {
    _isLoadingOwnership = true;
    _ownershipError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('════════════════════════════════════════════════════════════════');
        debugPrint('🎬 CARREGANDO OWNERSHIP - TopicViewerViewModel');
        debugPrint('════════════════════════════════════════════════════════════════');
        debugPrint('   🆔 UserId: $userId');
        debugPrint('   📌 Filtro: Apenas conteúdos criados/assignados pelo usuário');
      }

      final result = await _ownershipRepository.getUserVerifiedContents(
        userId: userId,
      );

      if (result.isOwner && result.contents != null) {
        _ownershipContents = result.contents!;
        if (kDebugMode) {
          debugPrint('   ✅ ${_ownershipContents.length} conteúdo(s) verificado(s) carregado(s)');
          for (final content in _ownershipContents) {
            debugPrint('      - ${content.channelName} (${content.title})');
          }
        }
      } else {
        _ownershipContents = [];
        if (kDebugMode) {
          debugPrint('   ⚠️  Nenhum conteúdo verificado (não é dono ou erro)');
        }
      }

      if (kDebugMode) {
        debugPrint('────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      _ownershipContents = [];
      _ownershipError = 'Erro ao carregar conteúdos verificados';
      if (kDebugMode) {
        debugPrint('   ❌ Erro ao carregar ownership: $e');
      }
    } finally {
      _isLoadingOwnership = false;
      notifyListeners();
    }
  }

  // ===== Métodos de Ordenação Local =====

  /// Ordena ownership contents por título (A-Z)
  void sortByTitleAscending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      a.title.toLowerCase().compareTo(b.title.toLowerCase())
    );
    notifyListeners();
    if (kDebugMode) {
      debugPrint('🔤 [TopicViewerVM] Ordenado por Título A-Z');
    }
  }

  /// Ordena ownership contents por título (Z-A)
  void sortByTitleDescending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      b.title.toLowerCase().compareTo(a.title.toLowerCase())
    );
    notifyListeners();
    if (kDebugMode) {
      debugPrint('🔤 [TopicViewerVM] Ordenado por Título Z-A');
    }
  }

  /// Ordena ownership contents por data de publicação (mais recentes primeiro)
  void sortByNewestPublished() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.publishedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.publishedAt) ?? DateTime(1970);
      return dateB.compareTo(dateA); // Decrescente
    });
    notifyListeners();
    if (kDebugMode) {
      debugPrint('📅 [TopicViewerVM] Ordenado por Mais Recentes');
    }
  }

  /// Ordena ownership contents por data de publicação (mais antigos primeiro)
  void sortByOldestPublished() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.publishedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.publishedAt) ?? DateTime(1970);
      return dateA.compareTo(dateB); // Crescente
    });
    notifyListeners();
    if (kDebugMode) {
      debugPrint('📅 [TopicViewerVM] Ordenado por Mais Antigos');
    }
  }

  /// Ordena ownership contents por nome do canal (A-Z)
  void sortByChannelNameAscending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      a.channelName.toLowerCase().compareTo(b.channelName.toLowerCase())
    );
    notifyListeners();
    if (kDebugMode) {
      debugPrint('📺 [TopicViewerVM] Ordenado por Canal A-Z');
    }
  }

  /// Ordena ownership contents por data de verificação (recentemente verificados)
  /// Usa verifiedAt como proxy para "adicionados ao sistema"
  void sortByRecentlyAdded() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.verifiedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.verifiedAt) ?? DateTime(1970);
      return dateB.compareTo(dateA); // Decrescente
    });
    notifyListeners();
    if (kDebugMode) {
      debugPrint('🆕 [TopicViewerVM] Ordenado por Verificados Recentemente');
    }
  }

  /// Embaralha ownership contents aleatoriamente
  void shuffleContents() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.shuffle();
    notifyListeners();
    if (kDebugMode) {
      debugPrint('🎲 [TopicViewerVM] Conteúdos embaralhados aleatoriamente');
    }
  }
}