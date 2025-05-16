import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/rouute_main_stuff/custom_route_manager.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_login_screen.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_register_screen.dart';
import 'app_routes.dart';

class AppModule extends Module {
  @override
  void routes(RouteManager r) {
    final routes = {
      AppRoutes.initial: const CoreAuthLoginScreen(), // SPLACH SCREEN???
      AppRoutes.login: const CoreAuthLoginScreen(),
      AppRoutes.register: const CoreAuthRegisterScreen(),
      // AppRoutes.admin: const AdminPage(),
      // AppRoutes.sales: const SalesPage(),
      // AppRoutes.salesProfile: const SalesPageProfile(),
      // AppRoutes.accessDenied: const AccessDeniedPage(),
    };

    //### HERE! WE HAVE AN IMPLICIT POLICY TO ALLOW NAVIGATION...
    CustomRouteManager.setupRoutes(
      routes: routes,
      routeManager: r,
      guards: AppRoutes.guardedRoutes,
    );
  }
}