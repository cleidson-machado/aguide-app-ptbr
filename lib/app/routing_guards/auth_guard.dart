import 'package:flutter_modular/flutter_modular.dart';

class AuthGuard extends RouteGuard {
  AuthGuard() : super(redirectTo: '/access-denied');

  @override
  Future<bool> canActivate(String path, ModularRoute route) async {
    bool isAuthenticated =
        false; // Simula autenticação (altere para true para testar)
    return isAuthenticated;
  }
}
