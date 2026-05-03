import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';

/// ViewModel para TopicViewerByUserScreen
/// Gerencia lógica de diferenciação entre CRIADOR e CONSUMIDOR
class TopicViewerViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;

  TopicViewerViewModel({
    UserRepositoryInterface? userRepository,
  }) : _userRepository = userRepository ?? injector<UserRepositoryInterface>();

  // ===== Estado de User Details (para diferenciação CRIADOR/CONSUMIDOR) =====
  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  // ===== Getters para User Details =====
  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;

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

  /// Retorna o título dinâmico da tela
  /// - CRIADOR: "| Meus Videos Criados |"
  /// - CONSUMIDOR: "| Meus Videos Visualizados |"
  String get screenTitle {
    final title = isContentCreator
        ? '| Meus Videos Criados |'
        : '| Meus Videos Visualizados |';

    if (kDebugMode) {
      debugPrint('🏷️  [TopicViewerVM] screenTitle: "$title"');
    }

    return title;
  }

  /// Carrega os detalhes do usuário via API
  /// 
  /// Consome: GET /api/v1/users/{userId}/details
  Future<void> loadUserDetails(String userId) async {
    _isLoadingUserDetails = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('📡 [TopicViewerVM] Carregando user details para userId: $userId');
      }

      _userDetails = await _userRepository.getUserDetails(userId);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════╗');
        debugPrint('║  ✅ USER DETAILS CARREGADOS - TopicViewerViewModel           ║');
        debugPrint('╚════════════════════════════════════════════════════════════════╝');
        debugPrint('   👤 Nome: ${_userDetails?.name}');
        debugPrint('   📧 Email: ${_userDetails?.email}');
        debugPrint('   📺 YouTube User ID: "${_userDetails?.youtubeUserId ?? "NULL"}"');
        debugPrint('   📺 YouTube Channel ID: "${_userDetails?.youtubeChannelId ?? "NULL"}"');
        debugPrint('   🎯 Tipo detectado: ${isContentCreator ? "CRIADOR" : "CONSUMIDOR"}');
        debugPrint('   🏷️  Título: "$screenTitle"');
        debugPrint('─────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TopicViewerVM] Erro ao carregar user details: $e');
      }
      // Não propaga erro para não bloquear a tela, apenas log
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }
}
