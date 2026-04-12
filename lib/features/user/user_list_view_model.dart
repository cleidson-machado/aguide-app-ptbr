import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// Sorting criteria for user list
enum UserSortCriteria {
  alphabeticalAZ,
  alphabeticalZA,
  relevance, // Future: by last interaction or profile completion
}

/// ViewModel for managing the list of system users
/// Follows MVVM architecture with state management via ChangeNotifier
class UserListViewModel extends ChangeNotifier {
  UserListViewModel({
    required UserRepositoryInterface repository,
  }) : _repository = repository;

  final UserRepositoryInterface _repository;

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  UserSortCriteria _currentSort = UserSortCriteria.alphabeticalAZ;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserSortCriteria get currentSort => _currentSort;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('👥 [UserListViewModel] $message');
    }
  }

  /// Load all users from the API (GET /users)
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    _log('loadUsers start');
    notifyListeners();

    try {
      final users = await _repository.getAll();
      _users = users;
      _applyCurrentSort();
      _log('loadUsers success count=${_users.length}');
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
      final users = await _repository.getAll();
      _users = users;
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
  void sortUsers(UserSortCriteria criteria) {
    _log('sortUsers criteria=$criteria');
    _currentSort = criteria;
    _applyCurrentSort();
    notifyListeners();
  }

  /// Apply current sort criteria to users list
  void _applyCurrentSort() {
    switch (_currentSort) {
      case UserSortCriteria.alphabeticalAZ:
        _users.sort((a, b) {
          final nameA = '${a.name} ${a.surname}'.toLowerCase();
          final nameB = '${b.name} ${b.surname}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
      case UserSortCriteria.alphabeticalZA:
        _users.sort((a, b) {
          final nameA = '${a.name} ${a.surname}'.toLowerCase();
          final nameB = '${b.name} ${b.surname}'.toLowerCase();
          return nameB.compareTo(nameA);
        });
        break;
      case UserSortCriteria.relevance:
        // TODO: Implement relevance sorting (by last interaction, profile completion, etc.)
        _log('sortUsers relevance not implemented yet, using A-Z fallback');
        _users.sort((a, b) {
          final nameA = '${a.name} ${a.surname}'.toLowerCase();
          final nameB = '${b.name} ${b.surname}'.toLowerCase();
          return nameA.compareTo(nameB);
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
