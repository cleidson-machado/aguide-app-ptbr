import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_repository.dart';
import 'package:portugal_guide/util/error_messages.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;
  final logger = Logger();

  UserViewModel({required UserRepositoryInterface repository}) : _userRepository = repository;

  List<UserModel> _users = [];
  String? error;
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  void _logError(String action, Object err, StackTrace stackTrace) {
    final className = runtimeType.toString();
    logger.e('$className - ERROR: "$action"', error: err, stackTrace: stackTrace);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      error = null; // ######################################### Clear the error message before loading users
      await Future.delayed(const Duration(seconds: 2)); // ##### Simulates a 2-second delay
      _users = await _userRepository.getAll();
    } catch (err, stackTrace) {
      _logError('loadUsers METHOD', err, stackTrace);
      error = ErrorMessages.defaultMsnFailedToLoadData;
      _users = [];
    }
    _setLoading(false);
  }

  Future<void> addUser(
    String name,
    String surname,
    String email,
    String password,
  ) async {
    _setLoading(true);
    try {
      final newUser = UserModel(
        id: '',
        name: name,
        surname: surname,
        email: email,
      );
      await _userRepository.create(newUser);
      await loadUsers();
    } catch (err, stackTrace) {
      _logError('addUser METHOD', err, stackTrace);
      error = ErrorMessages.defaultMsnFailedToSaveData;
      _setLoading(false);
    }
  }

  Future<void> updateUser(
    String id,
    String name,
    String surname,
    String email,
  ) async {
    _setLoading(true);
    try {
      final updatedUser = UserModel(
        id: id,
        name: name,
        surname: surname,
        email: email,
      );
      await _userRepository.update(updatedUser);
      await loadUsers();
    } catch (err, stackTrace) {
      _logError('updateUser METHOD', err, stackTrace);
      error = ErrorMessages.defaultMsnFailedToUpdateData;
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String id) async {
    _setLoading(true);
    try {
      await _userRepository.destroy(id);
      await loadUsers();
    } catch (err, stackTrace) {
      _logError('deleteUser METHOD', err, stackTrace);
      error = ErrorMessages.defaultMsnFailedToDestroyData;
      _setLoading(false);
    }
  }
}
