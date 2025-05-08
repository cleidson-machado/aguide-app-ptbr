import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_login_screen.dart';
import 'package:portugal_guide/features/core_auth_google/screens/core_google_login_screen.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';
import 'package:portugal_guide/features/user/screens/user_list_screen.dart';

//######################################################################################
//NOTE: DEFAULT FLUTTER NAVIGATOR STUFF FROM: *.*/flutter/packages/flutter/lib/src/widgets/navigator.dart
//######################################################################################

class AppRoutesHandler {
  static const String rootLogin = '/root_login';
  static const String googleLogin = '/google_login';
  //APPLE LOGIN
  //FACEBOOK LOGIN
  static const String home = '/home';
  static const String userList = '/user_list';
  

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case rootLogin:
        return CupertinoPageRoute(
          builder: (_) => const CoreAuthLoginScreen(),
          settings: settings,
        );

      case googleLogin:
        return CupertinoPageRoute(
          builder: (_) => const GoogleLoginScreen(),
          settings: settings,
        );

      case home:
        return CupertinoPageRoute(
          builder: (_) => const HomeContentTabScreen(),
          settings: settings,
        );

        ///##############################################################
        ///### THIS IS A EXAMPLE TO HOW PASS PARAMETER WHEN USE A ROUTE..
        // case home:
        // final Map<String, dynamic>? args =
        //     settings.arguments as Map<String, dynamic>?;
        // return CupertinoPageRoute(
        //   builder: (_) => HomeContentScreen(data: args?['data']),
        //   settings: settings,
        // );
        ///##############################################################

      case userList:
        return CupertinoPageRoute(
          builder: (_) => const UserListScreen(),//### HERE IS THE EXAMPLE TO HOW GET DATA FROM AN API STUFF... List of Moc Users...
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder: (_) => const CupertinoPageScaffold(
            child: Center(child: Text('Rota não encontrada!')),
          ),
        );
    }
  }
}
