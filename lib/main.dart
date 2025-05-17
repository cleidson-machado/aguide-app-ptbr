import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portugal_guide/app/app_custom_main_widget.dart';
import 'package:portugal_guide/app/helpers/env_error_warning.dart';
import 'package:portugal_guide/app/routing/app_route_module.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

final logger = Logger(); // Instância global do Logger
const String envFileName = ".env.dev";

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //USO CORRETO?
  _initializeApp().then((app) => runApp(app));
}

Future<Widget> _initializeApp() async {
  try {
    await dotenv.load(fileName: envFileName).timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Timeout while loading $envFileName'),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppTheme()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: ModularApp(
        module: AppRouteModule(),
        child: const AppMainWidget(),
      ),
    );
  } catch (e, stackTrace) {
    logger.e('Env loading error', error: e, stackTrace: stackTrace);
    return EnvErrorWarning(
      errorMessage: e.toString(),
      onRetry: () => main(),
    );
  }
}
