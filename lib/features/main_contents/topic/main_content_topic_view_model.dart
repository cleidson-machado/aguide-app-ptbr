import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_error_handler.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_criteria.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_option.dart';
import 'package:portugal_guide/features/main_contents/topic/sorting/main_content_sort_service.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';

class MainContentTopicViewModel extends ChangeNotifier {
  final MainContentTopicRepositoryInterface _repository;
  final UserRepositoryInterface _userRepository;
  late final AuthErrorHandler _errorHandler;

  MainContentTopicViewModel({
    MainContentTopicRepositoryInterface? repository,
    UserRepositoryInterface? userRepository,
  }) : _repository = repository ?? MainContentTopicRepository(),
       _userRepository = userRepository ?? injector<UserRepositoryInterface>() {
    // Inicializar error handler com token manager do injector
    _errorHandler = injector<AuthErrorHandler>();
  }

  // ===== Estado =====
  List<MainContentTopicModel> _contents = [];
  bool _isLoading = false;
  Exception? _error; // ✅ MUDANÇA: Armazenar Exception ao invés de String
  bool _isInitialized = false; // Flag para controlar se já foi inicializado
  
  // ===== Estado de User Details (para diferenciação CRIADOR/CONSUMIDOR) =====
  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  // ===== Estado de Paginação =====
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // ===== Estratégia de Ordenação Randômica =====
  MainContentSortCriteria? _currentSortCriteria;
  final MainContentSortService _sortService = MainContentSortService();
  bool _isManualFilterActive =
      false; // Flag para saber se filtro manual está ativo

  // ===== Estado de ToggleButtons individuais por item =====
  final Map<String, List<bool>> _toggleButtonStates = {};

  // ===== Getters públicos =====
  List<MainContentTopicModel> get contents => _contents;
  bool get isLoading => _isLoading;
  Exception? get error => _error; // ✅ MUDANÇA: Retornar Exception
  String? get errorMessage =>
      _error != null ? AuthErrorHandler.getUserFriendlyMessage(_error!) : null;
  bool get isAuthError =>
      _error != null ? AuthErrorHandler.isAuthError(_error!) : false;
  bool get isInitialized => _isInitialized;
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;
  MainContentSortCriteria? get currentSortCriteria => _currentSortCriteria;
  bool get isManualFilterActive => _isManualFilterActive;
  
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
        debugPrint('🔍 [isContentCreator] _userDetails é NULL → retornando FALSE (CONSUMIDOR)');
      }
      return false;
    }
    
    final hasYoutubeUserId = _userDetails!.youtubeUserId != null && 
                              _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null && 
                                 _userDetails!.youtubeChannelId!.isNotEmpty;
    
    final isCriador = hasYoutubeUserId && hasYoutubeChannelId;
    
    if (kDebugMode) {
      debugPrint('🔍 [isContentCreator] Verificação:');
      debugPrint('   youtubeUserId: ${_userDetails!.youtubeUserId ?? "NULL"} → hasYoutubeUserId: $hasYoutubeUserId');
      debugPrint('   youtubeChannelId: ${_userDetails!.youtubeChannelId ?? "NULL"} → hasYoutubeChannelId: $hasYoutubeChannelId');
      debugPrint('   Resultado: ${isCriador ? "CRIADOR" : "CONSUMIDOR"}');
    }
    
    return isCriador;
  }
  
  /// Retorna o label dinâmico para o header da tela de tópicos
  /// Diferencia entre CRIADOR e CONSUMIDOR de conteúdo
  String get topicHeaderLabel {
    final label = isContentCreator 
        ? '| TEMAS - Perfil CRIADOR de Conteúdo |' 
        : '| TEMAS - Perfil CONSUMIDOR de Conteúdo |';
    
    if (kDebugMode) {
      debugPrint('🏷️  [topicHeaderLabel] Retornando: "$label"');
    }
    
    return label;
  }
  
  /// Retorna o nome do usuário para personalização (usado na animação)
  String get userName => _userDetails?.name ?? '';

  // ===== Gerenciamento de ToggleButtons por item =====
  
  /// Obtém o estado dos botões para um item específico
  /// Retorna [false, true, false] (DETALHES selecionado) como padrão
  List<bool> getToggleButtonState(String contentId) {
    return _toggleButtonStates.putIfAbsent(
      contentId,
      () => [false, true, false], // Padrão: DETALHES selecionado
    );
  }

  /// Atualiza o estado dos botões para um item específico
  /// Single-select: apenas um botão pode estar ativo por vez
  void updateToggleButtonState(String contentId, int selectedIndex) {
    final currentState = getToggleButtonState(contentId);
    
    // Single-select: desmarcar todos e marcar apenas o selecionado
    for (int i = 0; i < currentState.length; i++) {
      currentState[i] = i == selectedIndex;
    }
    
    _toggleButtonStates[contentId] = currentState;
    notifyListeners(); // Notifica apenas o item específico
  }

  /// Limpa estados de botões (útil ao recarregar lista)
  void clearToggleButtonStates() {
    _toggleButtonStates.clear();
  }

  // ===== Ações =====
  
  /// Carrega os detalhes do usuário via API
  /// 
  /// Consome: GET /api/v1/users/{userId}/details
  Future<void> loadUserDetails(String userId) async {
    _isLoadingUserDetails = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('📡 [MainContentTopicViewModel] Carregando user details para userId: $userId');
      }

      _userDetails = await _userRepository.getUserDetails(userId);

      if (kDebugMode) {
        debugPrint('');
        debugPrint('╔════════════════════════════════════════════════════════════════════╗');
        debugPrint('║  ✅ USER DETAILS CARREGADOS COM SUCESSO                            ║');
        debugPrint('╚════════════════════════════════════════════════════════════════════╝');
        debugPrint('   👤 Nome: ${_userDetails?.name}');
        debugPrint('   📧 Email: ${_userDetails?.email}');
        debugPrint('   📺 YouTube User ID: "${_userDetails?.youtubeUserId ?? "NULL"}"');
        debugPrint('   📺 YouTube Channel ID: "${_userDetails?.youtubeChannelId ?? "NULL"}"');
        debugPrint('   🎯 Tipo detectado: ${isContentCreator ? "CRIADOR" : "CONSUMIDOR"}');
        debugPrint('   🏷️  Label: "$topicHeaderLabel"');
        debugPrint('───────────────────────────────────────────────────────────────────');
        debugPrint('');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [MainContentTopicViewModel] Erro ao carregar user details: $e');
      }
      // Não propaga erro para não bloquear a tela, apenas log
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }
  
  Future<void> loadAllContents() async {
    _setLoading(true);
    try {
      final items =
          await _repository
              .getAll(); //Esse GetAll() é o sobrescrito na respectiva Repository
      _contents = items;
      _error = null;
    } catch (e) {
      // ✅ NOVO: Usar error handler para converter em exception amigável
      _error = _errorHandler.handleError(e, context: 'loadAllContents');
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro em loadAllContents()");
        if (_error is AuthException) {
          debugPrint((_error as AuthException).toTechnicalString());
        }
      }
    }
    _setLoading(false);
  }

  /// Carrega a primeira página de conteúdos de forma paginada
  /// NOTA: App usa paginação 1-based (page 1, 2, 3...) que é convertida para 0-based na API
  /// 🎲 RANDOMIZAÇÃO: Escolhe aleatoriamente uma estratégia de ordenação a cada carregamento
  Future<void> loadPagedContents() async {
    if (kDebugMode) {
      debugPrint(
        "📄 [MainContentTopicViewModel] Iniciando loadPagedContents()",
      );
    }

    // 🎲 Escolher estratégia aleatória de ordenação
    final randomOption = _sortService.getRandomOption();
    _currentSortCriteria = MainContentSortCriteria.fromOption(randomOption);
    _isManualFilterActive = false; // Desativa filtro manual quando randomiza

    if (kDebugMode) {
      debugPrint(
        "🎲 [MainContentTopicViewModel] Estratégia selecionada: ${_currentSortCriteria!.displayName}",
      );
      debugPrint(
        "   Campo: ${_currentSortCriteria!.field}, Ordem: ${_currentSortCriteria!.order}",
      );
    }

    _currentPage = 1; // App inicia em page=1 (será convertido para API page=0)
    _hasMorePages = true;
    _contents = [];
    _setLoading(true);
    try {
      final items = await _repository.getAllPaged(
        page: _currentPage, // page=1 → API recebe page=0
        size: _pageSize,
        sortField: _currentSortCriteria!.field,
        sortOrder: _currentSortCriteria!.order,
      );
      if (kDebugMode) {
        debugPrint(
          "📄 [MainContentTopicViewModel] Página $_currentPage carregada com ${items.length} itens",
        );
      }

      _contents = items;
      _error = null;
      _isInitialized = true; // Marca como inicializado

      // ✅ LÓGICA CORRIGIDA: Verifica se há mais páginas
      // Se recebeu menos itens que o pageSize, acabaram as páginas
      if (items.length < _pageSize) {
        _hasMorePages = false;
        if (kDebugMode) {
          debugPrint(
            "ℹ️  [MainContentTopicViewModel] Última página atingida (${items.length} < $_pageSize)",
          );
        }
      } else {
        _hasMorePages = true;
        if (kDebugMode) {
          debugPrint(
            "ℹ️  [MainContentTopicViewModel] Há mais páginas disponíveis (recebidos $_pageSize itens)",
          );
        }
      }
    } catch (e) {
      // ✅ NOVO: Usar error handler para converter em exception amigável
      _error = _errorHandler.handleError(e, context: 'loadPagedContents');
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro em loadPagedContents()");
        if (_error is AuthException) {
          debugPrint((_error as AuthException).toTechnicalString());
        }
      }
    }
    _setLoading(false);
  }

  /// Carrega conteúdos apenas se ainda não foi inicializado
  /// Usado no initState() para evitar recarregamento ao voltar da tab
  Future<void> loadPagedContentsIfNeeded() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint(
          "✅ [MainContentTopicViewModel] Primeira inicialização - carregando dados",
        );
      }
      await loadPagedContents();
    } else {
      if (kDebugMode) {
        debugPrint(
          "ℹ️  [MainContentTopicViewModel] Já inicializado - reutilizando dados em cache",
        );
      }
    }
  }

  /// Carrega próxima página e adiciona aos conteúdos existentes (paginação incremental)
  /// Mantém a mesma estratégia de ordenação da sessão atual
  Future<void> loadNextPage() async {
    if (!_hasMorePages || _isLoadingMore) return;

    if (kDebugMode) {
      debugPrint("📄 [MainContentTopicViewModel] Iniciando loadNextPage()");
      debugPrint(
        "📄 [MainContentTopicViewModel] currentPage: $_currentPage, hasMorePages: $_hasMorePages, isLoadingMore: $_isLoadingMore",
      );
      debugPrint(
        "📄 [MainContentTopicViewModel] Total de itens antes: ${_contents.length}",
      );
      debugPrint(
        "🎲 [MainContentTopicViewModel] Mantendo estratégia: ${_currentSortCriteria?.displayName}",
      );
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      if (kDebugMode) {
        debugPrint(
          "📄 [MainContentTopicViewModel] Requisitando página: $nextPage",
        );
      }

      final items = await _repository.getAllPaged(
        page: nextPage,
        size: _pageSize,
        sortField: _currentSortCriteria?.field,
        sortOrder: _currentSortCriteria?.order,
      );

      if (kDebugMode) {
        debugPrint(
          "📄 [MainContentTopicViewModel] Recebidos ${items.length} itens da página $nextPage",
        );
      }

      // Adicionar os novos itens à lista existente
      _contents.addAll(items);
      _currentPage = nextPage;

      if (kDebugMode) {
        debugPrint(
          "📄 [MainContentTopicViewModel] Total de itens após: ${_contents.length}",
        );
      }

      // Se recebeu menos itens que o pageSize, não há mais páginas
      if (items.length < _pageSize) {
        _hasMorePages = false;
        if (kDebugMode) {
          debugPrint(
            "✅ [MainContentTopicViewModel] Fim da paginação atingido! (${items.length} < $_pageSize)",
          );
        }
      }

      _error = null;
    } catch (e) {
      // ✅ NOVO: Usar error handler
      _error = _errorHandler.handleError(e, context: 'loadNextPage');
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro em loadNextPage()");
        if (_error is AuthException) {
          debugPrint((_error as AuthException).toTechnicalString());
        }
      }
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> searchContents(String title) async {
    if (title.isEmpty) {
      await loadPagedContents();
      return;
    }
    clearToggleButtonStates(); // Limpa estados ao buscar
    _setLoading(true);
    try {
      final items = await _repository.searchByTitle(title);
      _contents = items;
      _error = null;
    } catch (e) {
      // ✅ NOVO: Usar error handler
      _error = _errorHandler.handleError(e, context: 'searchContents');
      if (kDebugMode && _error is AuthException) {
        debugPrint((_error as AuthException).toTechnicalString());
      }
    }
    _setLoading(false);
  }

  /// Recarrega a lista do início (usado em pull-to-refresh)
  /// Reseta estado de paginação e recarrega primeira página
  Future<void> refreshContents() async {
    if (kDebugMode) {
      debugPrint("🔄 [MainContentTopicViewModel] Iniciando refreshContents()");
    }
    _currentPage = 1;
    _contents.clear();
    _hasMorePages = true;
    _error = null;
    clearToggleButtonStates(); // Limpa estados de botões ao recarregar
    await loadPagedContents();
  }

  /// Aplica um filtro manual específico (não randômico)
  /// Marca o filtro como ativo para exibir botão de reset
  Future<void> applyManualFilter(MainContentSortOption option) async {
    if (kDebugMode) {
      debugPrint(
        "🔍 [MainContentTopicViewModel] Aplicando filtro manual: ${option.displayName}",
      );
    }

    _currentSortCriteria = MainContentSortCriteria.fromOption(option);
    _isManualFilterActive = true; // Ativa flag de filtro manual

    if (kDebugMode) {
      debugPrint(
        "🔧 [MainContentTopicViewModel] Filtro aplicado: ${_currentSortCriteria!.displayName}",
      );
    }

    _currentPage = 1;
    _hasMorePages = true;
    _contents = [];
    clearToggleButtonStates(); // Limpa estados de botões ao aplicar filtro
    _setLoading(true);

    try {
      final items = await _repository.getAllPaged(
        page: _currentPage,
        size: _pageSize,
        sortField: _currentSortCriteria!.field,
        sortOrder: _currentSortCriteria!.order,
      );

      _contents = items;
      _error = null;
      _isInitialized = true;

      if (items.length < _pageSize) {
        _hasMorePages = false;
      }

      if (kDebugMode) {
        debugPrint(
          "✅ [MainContentTopicViewModel] Filtro manual aplicado com sucesso!",
        );
      }
    } catch (e) {
      // ✅ NOVO: Usar error handler
      _error = _errorHandler.handleError(e, context: 'applyManualFilter');
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro ao aplicar filtro");
        if (_error is AuthException) {
          debugPrint((_error as AuthException).toTechnicalString());
        }
      }
    }

    _setLoading(false);
  }

  /// Reseta filtro manual e volta ao modo randômico
  Future<void> resetToRandomMode() async {
    if (kDebugMode) {
      debugPrint(
        "🔄 [MainContentTopicViewModel] Resetando para modo randômico",
      );
    }
    _isManualFilterActive = false;
    clearToggleButtonStates(); // Limpa estados de botões ao resetar
    await loadPagedContents(); // Carrega com estratégia randômica
  }

  // ===== Configuração do Botão de Validação =====
  
  /// Retorna a configuração do botão de validação baseado no validationHash
  /// - Se validationHash != null: Botão vermelho "VIDEO OU CANAL - COM AUTORIA RECONHECIDA!"
  /// - Se validationHash == null: Botão azul escuro "ESTE VÍDEO É SEU? MONETIZE AGORA MESMO!"
  ValidationButtonConfig getValidationButtonConfig(MainContentTopicModel content) {
    if (content.validationHash != null && content.validationHash!.isNotEmpty) {
      return const ValidationButtonConfig(
        text: 'VIDEO OU CANAL - COM AUTORIA RECONHECIDA!',
        backgroundColor: Color(0xFFB71C1C), // Vermelho escuro
      );
    } else {
      return const ValidationButtonConfig(
        text: 'ESTE VÍDEO É SEU? MONETIZE AGORA MESMO!',
        backgroundColor: Color(0xFF1565C0), // Azul escuro (Material Blue 800)
      );
    }
  }

  // ===== Ownership (Verificação de Autoria) =====
  
  /// Verifica se o usuário logado é dono do conteúdo especificado
  /// 
  /// Retorna [OwnershipResult] com informações sobre a verificação:
  /// - Se `isOwner = true`: usuário é dono, modal pode ser exibida
  /// - Se `isOwner = false`: usuário NÃO é dono, exibir mensagem de alerta
  /// 
  /// [contentId] - ID do conteúdo a verificar
  Future<OwnershipResult> checkContentOwnership(String contentId) async {
    if (kDebugMode) {
      debugPrint('🔍 [MainContentTopicViewModel] Verificando ownership do conteúdo');
      debugPrint('   Content ID: $contentId');
    }

    try {
      // Obter userId do token JWT
      final tokenManager = injector<AuthTokenManager>();
      final userId = tokenManager.getUserId();

      if (userId == null || userId.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ [MainContentTopicViewModel] Erro: userId não encontrado no token');
        }
        
        return OwnershipResult.notOwner(
          OwnershipErrorModel(
            error: 'INVALID_TOKEN',
            message: 'Token de autenticação inválido. Faça login novamente.',
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('✅ [MainContentTopicViewModel] User ID extraído: $userId');
      }

      // 📍 CONSUMO DO ENDPOINT: GET /api/v1/ownership/user/{userId}/content
      // Chama repository que faz a requisição HTTP para verificar ownership
      final ownershipRepo = injector<OwnershipRepositoryInterface>();
      final result = await ownershipRepo.checkContentOwnership(
        userId: userId,
        contentId: contentId,
      );

      if (result.isOwner) {
        if (kDebugMode) {
          debugPrint('✅ [MainContentTopicViewModel] Ownership confirmado!');
          debugPrint('   Conteúdos verificados: ${result.contents?.length ?? 0}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ [MainContentTopicViewModel] Ownership não confirmado');
          debugPrint('   Erro: ${result.error?.error}');
          debugPrint('   Mensagem: ${result.error?.message}');
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [MainContentTopicViewModel] Erro ao verificar ownership: $e');
      }
      
      return OwnershipResult.notOwner(
        OwnershipErrorModel(
          error: 'UNEXPECTED_ERROR',
          message: 'Erro inesperado ao verificar autoria. Tente novamente.',
          timestamp: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  /// 🆕 Valida autoria via POST /api/v1/ownership/validate
  /// 
  /// Envia requisição POST para validar se o usuário é dono do conteúdo
  /// Retorna [OwnershipValidationResponse] com status:
  /// - VERIFIED: autoria confirmada com validationHash
  /// - REJECTED: autoria negada (canais não coincidem)
  /// 
  /// [contentId] - ID do conteúdo a validar
  Future<OwnershipValidationResponse> validateOwnershipViaPost(
    String contentId,
  ) async {
    if (kDebugMode) {
      debugPrint('🔐 [MainContentTopicViewModel] Validando ownership via POST');
      debugPrint('   Content ID: $contentId');
    }

    // Obter userId do token JWT
    final tokenManager = injector<AuthTokenManager>();
    final userId = tokenManager.getUserId();

    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ [MainContentTopicViewModel] Erro: userId não encontrado no token');
      }

      // Lançar exceção para ser tratada na UI
      throw Exception('Token de autenticação inválido. Faça login novamente.');
    }

    if (kDebugMode) {
      debugPrint('✅ [MainContentTopicViewModel] User ID extraído: $userId');
    }

    // 📍 CONSUMO DO ENDPOINT: POST /api/v1/ownership/validate
    final ownershipRepo = injector<OwnershipRepositoryInterface>();
    final response = await ownershipRepo.validateOwnership(
      userId: userId,
      contentId: contentId,
    );

    if (kDebugMode) {
      if (response.isVerified) {
        debugPrint('✅ [MainContentTopicViewModel] Ownership VERIFICADO!');
        debugPrint('   ValidationHash: ${response.validationHash}');
        debugPrint('   Message: ${response.message}');
      } else {
        debugPrint('❌ [MainContentTopicViewModel] Ownership REJEITADO');
        debugPrint('   Motivo: ${response.message}');
      }
    }

    return response;
  }

  // ===== Helpers internos =====
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// Configuração do botão de validação de autoria
/// Encapsula texto e cor de fundo baseado no estado do validationHash
class ValidationButtonConfig {
  final String text;
  final Color backgroundColor;

  const ValidationButtonConfig({
    required this.text,
    required this.backgroundColor,
  });
}
