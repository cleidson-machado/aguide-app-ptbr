import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/rouute_main_stuff/app_routes.dart';

class CustomRouteManager {
  static void setupRoutes({
    required Map<String, Widget> routes,
    required RouteManager routeManager,
    Map<String, List<RouteGuard>>? guards,
    TransitionType defaultTransition = TransitionType.rightToLeftWithFade,
    Duration defaultDuration = const Duration(milliseconds: 300),
  }) {
    routes.forEach((path, widget) {
      routeManager.child(
        path,
        child: (context) => widget,
        transition: path == AppRoutes.initial 
            ? TransitionType.fadeIn 
            : defaultTransition,
        duration: defaultDuration,
        guards: guards?[path] ?? [],
      );
    });
  }
}