import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/repositories/api_repository.dart';
import 'package:portugal_guide/app/core/repositories/base_repository.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/features/user/user_model.dart';

class UserController extends ChangeNotifier {
  final BaseRepository<UserModel> _repository;

  // Aceita o endpoint como parâmetro
  UserController({String? endpoint, BaseRepository<UserModel>? repository})
      : _repository = repository ?? ApiRepository<UserModel>(
          endpoint: endpoint ?? '${EnvKeyHelperConfig.mocApi1}/user/', // Usa o endpoint fornecido ou aquele QUE ESTÁ NO HELPER como padrão! Posso Trabalhar aqui com mais de um? Veiricar!!
          fromMap: UserModel.fromMap,
        );

  bool _isLoading = false;
  String _error = '';
  List<UserModel> _users = [];

  // Getters para a view
  bool get isLoading => _isLoading;
  String get error => _error;
  List<UserModel> get usersModel => _users;

  Future<void> getUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      _users = await _repository.getAll();
      _error = '';
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.create(user);
      await getUsers(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}