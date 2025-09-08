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

  // ===== Getters públicos =====
  List<MainContentTopicModel> get contents => _contents;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<void> searchContents(String title) async {
    if (title.isEmpty) {
      await loadAllContents();
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

  // ===== Helpers internos =====
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}