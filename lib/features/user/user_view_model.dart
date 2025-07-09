import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  String? error;

  List<UserModel> get users => _users;


  Future<void> loadUsers() async {
    try {
      error = null;
      _users = await _userService.fetchUsers();
    } catch (e) {
      error = e.toString();
      _users = [];
    }
    notifyListeners();
  }

  // Assinatura atualizada
  Future<void> addUser(String name, String surname, String email, String password) async {
    await _userService.addUser(name, surname, email, password);
    await loadUsers(); // Recarrega a lista para mostrar o novo usuário
  }

  // Assinatura atualizada
  Future<void> updateUser(String id, String name, String surname, String email) async {
    await _userService.updateUser(id, name, surname, email);
    await loadUsers();
  }

  // Assinatura atualizada
  Future<void> deleteUser(String id) async {
    await _userService.deleteUser(id);
    await loadUsers();
  }

}