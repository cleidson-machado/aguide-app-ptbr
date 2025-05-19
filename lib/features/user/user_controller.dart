import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_service.dart';

//######################################################################################
//### NOTE: MVC - CLASSIC STYLE EXAMPLE
//######################################################################################

class UserController extends ChangeNotifier {
  final UserService _service;

  UserController(this._service);

  var isLoading = false;
  var error = '';
  var usersModel = <UserModel>[];

  Future<List<UserModel>> getUsers() async {
    try {
      isLoading = true;
      notifyListeners(); // Notify UI about loading state

      final users = await _service.fetchUsers();
      usersModel = users;
      error = ''; // Clear any previous errors
    } catch (err) {
      error = err.toString();
      usersModel = []; // Ensure a list is always returned
    } finally {
      isLoading = false;
      notifyListeners(); // Notify UI about state change
    }

    return usersModel; // Always return a list
  }
}