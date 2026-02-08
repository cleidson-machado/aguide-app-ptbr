import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository.dart';
import 'package:portugal_guide/features/main_contents/topic/content_sort_criteria.dart';
import 'package:portugal_guide/features/main_contents/topic/content_sort_option.dart';
import 'package:portugal_guide/features/main_contents/topic/content_sort_service.dart';

class MainContentTopicViewModel extends ChangeNotifier {
  final MainContentTopicRepositoryInterface _repository;

  MainContentTopicViewModel({MainContentTopicRepositoryInterface? repository})
    : _repository = repository ?? MainContentTopicRepository();

  // ===== Estado =====
  List<MainContentTopicModel> _contents = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false; // Flag para controlar se já foi inicializado

  // ===== Estado de Paginação =====
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // ===== Estratégia de Ordenação Randômica =====
  ContentSortCriteria? _currentSortCriteria;
  final ContentSortService _sortService = ContentSortService();
  bool _isManualFilterActive =
      false; // Flag para saber se filtro manual está ativo

  // ===== Getters públicos =====
  List<MainContentTopicModel> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;
  ContentSortCriteria? get currentSortCriteria => _currentSortCriteria;
  bool get isManualFilterActive => _isManualFilterActive;

  // ===== Ações =====
  Future<void> loadAllContents() async {
    _setLoading(true);
    try {
      final items =
          await _repository
              .getAll(); //Esse GetAll() é o sobrescrito na respectiva Repository
      _contents = items;
      _error = null;
    } catch (e) {
      _error = "Erro ao carregar conteúdos: $e";
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
    _currentSortCriteria = ContentSortCriteria.fromOption(randomOption);
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
      _error = "Erro ao carregar conteúdos: $e";
      if (kDebugMode) {
        debugPrint(
          "❌ [MainContentTopicViewModel] Erro em loadPagedContents(): $e",
        );
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
      _error = "Erro ao carregar próxima página: $e";
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro em loadNextPage(): $e");
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
    _setLoading(true);
    try {
      final items = await _repository.searchByTitle(title);
      _contents = items;
      _error = null;
    } catch (e) {
      _error = "Erro na busca: $e";
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
    await loadPagedContents();
  }

  /// Aplica um filtro manual específico (não randômico)
  /// Marca o filtro como ativo para exibir botão de reset
  Future<void> applyManualFilter(ContentSortOption option) async {
    if (kDebugMode) {
      debugPrint(
        "🔍 [MainContentTopicViewModel] Aplicando filtro manual: ${option.displayName}",
      );
    }

    _currentSortCriteria = ContentSortCriteria.fromOption(option);
    _isManualFilterActive = true; // Ativa flag de filtro manual

    if (kDebugMode) {
      debugPrint(
        "🔧 [MainContentTopicViewModel] Filtro aplicado: ${_currentSortCriteria!.displayName}",
      );
    }

    _currentPage = 1;
    _hasMorePages = true;
    _contents = [];
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
      _error = "Erro ao aplicar filtro: $e";
      if (kDebugMode) {
        debugPrint("❌ [MainContentTopicViewModel] Erro ao aplicar filtro: $e");
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
    await loadPagedContents(); // Carrega com estratégia randômica
  }

  // ===== Helpers internos =====
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
