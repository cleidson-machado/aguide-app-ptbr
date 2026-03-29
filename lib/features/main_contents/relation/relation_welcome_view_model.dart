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

  /// Retorna o tipo de usuário para exibição (usado na view com estilo customizado)
  String get userTypeLabel => isContentCreator ? '| CRIADOR de Conteúdo |' : '| CONSUMIDOR de Conteúdo |';

  /// Primeira parte da mensagem (antes do tipo de usuário)
  String get welcomeMessagePrefix => 'Que bom ter você aqui! \n Identificamos seu perfil como: \n\n ';

  /// Segunda parte da mensagem (depois do tipo de usuário) - dinâmica por tipo
  String get welcomeMessageSuffix {
    if (isContentCreator) {
      // Mensagem para CRIADOR (Produtor de Conteúdo)
      return '\n\nPara liberar todas as funcionalidades da área de Relações e te ajudar a aumentar '
          'seus ganhos e monetização, precisamos que você preencha um formulário '
          'com 10 perguntas simples.\n\n'
          'As respostas são fundamentais para entendermos seu padrão e fazer todos '
          'os ajustes necessários e outras adaptações afins.\n\n'
          'Responda com sinceridade '
          'as questões. \n No final, te avisamos '
          'por e-mail ou aqui no App com '
          'uma Mensagem personalizada.';
    } else {
      // Mensagem para CONSUMIDOR
      return '\n\nPara liberar tudo da área de Relações e te ajudar \n a encontrar, detalhadamente, '
          'tudo que precisa, precisamos que você preencha um formulário '
          'com 10 perguntas simples.\n\n'
          'As respostas são fundamentais para entendermos seu padrão e fazer todos '
          'os ajustes necessários \n e outras adaptações afins.\n\n'
          'Responda com sinceridade as questões. \n No final, te avisamos '
          'por e-mail ou aqui no App \n com uma Mensagem personalizada.';
    }
  }

  /// Mensagem completa (mantido para compatibilidade)
  String get welcomeMessage => welcomeMessagePrefix + userTypeLabel + welcomeMessageSuffix;

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
