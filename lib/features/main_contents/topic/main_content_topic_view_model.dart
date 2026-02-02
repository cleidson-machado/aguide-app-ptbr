import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository.dart';

class MainContentTopicViewModel extends ChangeNotifier {
  final MainContentTopicRepositoryInterface _repository;

  MainContentTopicViewModel({MainContentTopicRepositoryInterface? repository})
      : _repository = repository ?? MainContentTopicRepository();

  // ===== Estado =====
  List<MainContentTopicModel> _contents = [];
  bool _isLoading = false;
  String? _error;
  
  // ===== Estado de Paginação =====
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // ===== Getters públicos =====
  List<MainContentTopicModel> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;

  // ===== Ações =====
  Future<void> loadAllContents() async {
    _setLoading(true);
    try {
      final items = await _repository.getAll(); //Esse GetAll() é o sobrescrito na respectiva Repository
      _contents = items;
      _error = null;
    } catch (e) {
      _error = "Erro ao carregar conteúdos: $e";
    }
    _setLoading(false);
  }

  /// Carrega a primeira página de conteúdos de forma paginada
  Future<void> loadPagedContents() async {
    print("📄 [MainContentTopicViewModel] Iniciando loadPagedContents()");
    
    _currentPage = 1;
    _hasMorePages = true;
    _contents = [];
    _setLoading(true);
    try {
      final items = await _repository.getAllPaged(
        page: _currentPage,
        size: _pageSize,
      );
      print("📄 [MainContentTopicViewModel] Página 1 carregada com ${items.length} itens");
      
      _contents = items;
      _error = null;
      
      // Se recebeu menos itens que o pageSize, não há mais páginas
      if (items.length < _pageSize) {
        _hasMorePages = false;
        print("ℹ️  [MainContentTopicViewModel] Nota: Apenas 1 página disponível");
      } else {
        print("ℹ️  [MainContentTopicViewModel] Há mais páginas disponíveis");
      }
    } catch (e) {
      _error = "Erro ao carregar conteúdos: $e";
      print("❌ [MainContentTopicViewModel] Erro em loadPagedContents(): $e");
    }
    _setLoading(false);
  }

  /// Carrega próxima página e adiciona aos conteúdos existentes (paginação incremental)
  Future<void> loadNextPage() async {
    if (!_hasMorePages || _isLoadingMore) return;
    
    print("📄 [MainContentTopicViewModel] Iniciando loadNextPage()");
    print("📄 [MainContentTopicViewModel] currentPage: $_currentPage, hasMorePages: $_hasMorePages, isLoadingMore: $_isLoadingMore");
    print("📄 [MainContentTopicViewModel] Total de itens antes: ${_contents.length}");
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final nextPage = _currentPage + 1;
      print("📄 [MainContentTopicViewModel] Requisitando página: $nextPage");
      
      final items = await _repository.getAllPaged(
        page: nextPage,
        size: _pageSize,
      );
      
      print("📄 [MainContentTopicViewModel] Recebidos ${items.length} itens da página $nextPage");
      
      // Adicionar os novos itens à lista existente
      _contents.addAll(items);
      _currentPage = nextPage;
      
      print("📄 [MainContentTopicViewModel] Total de itens após: ${_contents.length}");
      
      // Se recebeu menos itens que o pageSize, não há mais páginas
      if (items.length < _pageSize) {
        _hasMorePages = false;
        print("✅ [MainContentTopicViewModel] Fim da paginação atingido! (${items.length} < $_pageSize)");
      }
      
      _error = null;
    } catch (e) {
      _error = "Erro ao carregar próxima página: $e";
      print("❌ [MainContentTopicViewModel] Erro em loadNextPage(): $e");
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
    print("🔄 [MainContentTopicViewModel] Iniciando refreshContents()");
    _currentPage = 1;
    _contents.clear();
    _hasMorePages = true;
    _error = null;
    await loadPagedContents();
  }

  // ===== Helpers internos =====
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}