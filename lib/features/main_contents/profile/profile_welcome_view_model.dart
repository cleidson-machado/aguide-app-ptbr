import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';

/// ViewModel para tela de boas-vindas do formulário de perfil
/// Determina se o usuário é CRIADOR ou CONSUMIDOR baseado em dados do YouTube
class ProfileWelcomeViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;

  ProfileWelcomeViewModel(this._userRepository);

  // Estado
  UserDetailsModel? _userDetails;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Determina se o usuário é CRIADOR (Produtor de Conteúdo)
  /// 
  /// Lógica: Se ambos youtubeUserId E youtubeChannelId são não-nulos → CRIADOR
  /// Qualquer outra combinação → CONSUMIDOR
  bool get isContentCreator {
    if (_userDetails == null) return false;
    
    final hasYoutubeUserId = _userDetails!.youtubeUserId != null && 
                              _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null && 
                                 _userDetails!.youtubeChannelId!.isNotEmpty;
    
    return hasYoutubeUserId && hasYoutubeChannelId;
  }

  /// Retorna o nome do usuário para personalização da mensagem
  String get userName => _userDetails?.name ?? 'Usuário';

  /// Mensagem dinâmica baseada no tipo de usuário (CRIADOR ou CONSUMIDOR)
  String get welcomeMessage {
    if (isContentCreator) {
      return 'Que bom ter você aqui! \n Identificamos seu perfil como \n\n Produtor de Conteúdo.\n\n'
          'Para liberar todas as funcionalidades da área de Relações e te ajudar a aumentar '
          'seus ganhos e monetização, precisamos que você preencha um formulário \n com 10 perguntas simples.\n\n'
          'As respostas são fundamentais para entendermos seu padrão e fazer os ajustes necessários.\n\n'
          'Responda com sinceridade \n as questões. No final, avisamos \n por e-mail '
          'ou aqui no App com \n uma Mensagem personalizada.';
    } else {
      return 'Que bom ter você aqui! \n Identificamos seu perfil como \n\n Consumidor de Conteúdo.\n\n'
          'Para liberar todas as funcionalidades da área de Relações e te ajudar a aumentar '
          'seus ganhos e monetização, precisamos que você preencha um formulário \n com 10 perguntas simples.\n\n'
          'As respostas são fundamentais para entendermos seu padrão e fazer os ajustes necessários.\n\n'
          'Responda com sinceridade \n as questões. No final, avisamos \n por e-mail '
          'ou aqui no App com \n uma Mensagem personalizada.';
    }
  }

  /// Carrega os detalhes do usuário via API
  /// 
  /// Consome: GET /api/v1/users/{userId}/details
  Future<void> loadUserDetails(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('📋 [ProfileWelcomeViewModel] Carregando detalhes do usuário: $userId');
      }

      final details = await _userRepository.getUserDetails(userId);
      
      _userDetails = details;
      _error = null;

      if (kDebugMode) {
        print('✅ [ProfileWelcomeViewModel] Detalhes carregados com sucesso');
        print('   Nome: ${details.fullName}');
        print('   YouTube User ID: ${details.youtubeUserId ?? "null"}');
        print('   YouTube Channel ID: ${details.youtubeChannelId ?? "null"}');
        print('   Tipo: ${isContentCreator ? "CRIADOR" : "CONSUMIDOR"}');
      }
    } catch (e) {
      _error = 'Erro ao carregar informações do usuário: $e';
      
      if (kDebugMode) {
        print('❌ [ProfileWelcomeViewModel] Erro: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa o estado do ViewModel
  void clearState() {
    _userDetails = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearState();
    super.dispose();
  }
}
