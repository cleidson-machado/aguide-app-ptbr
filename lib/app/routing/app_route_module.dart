import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/routing/app_route_manager.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_login_screen.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_register_screen.dart';
// import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';
import 'package:portugal_guide/features/user/screens/user_list_screen.dart';
import 'app_routes.dart';

class AppRouteModule extends Module {
  @override
  void routes(RouteManager r) {
    final routes = {
      AppRoutes.initial: const UserListScreen(), // SPLACH SCREEN???
      //AppRoutes.initial: const HomeContentTabScreen(), // SPLACH SCREEN???
      //AppRoutes.initial: const CoreAuthLoginScreen(), // SPLACH SCREEN???
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
      guards: AppRoutes.basicAuthGuardGroupsTest,
    );
  }
}