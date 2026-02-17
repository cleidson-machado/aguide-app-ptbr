import 'package:flutter/cupertino.dart';

class AuthGoogleLoginScreen extends StatelessWidget {
  final String? data;

  const AuthGoogleLoginScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text("Home"),
      ),
      child: Center(
        child: Text(data ?? "Nenhum dado recebido no AuthGoogleLoginScreen!!"),
      ),
    );
  }
}
