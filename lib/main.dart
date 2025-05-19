import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portugal_guide/app/app_custom_main_widget.dart';
import 'package:portugal_guide/app/core/rest_api_provider.dart';
import 'package:portugal_guide/app/helpers/env_error_warning_widget.dart';
import 'package:portugal_guide/app/routing/app_route_module.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

final logger = Logger(); // Instância global do Logger
const String envFileName = ".env.dev";

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //USO CORRETO? YES!!!!!
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
        ChangeNotifierProvider(create: (_) => AppTheme()), // REFACTOR HERE!! LEAVE ALL THIS GUYS WITH THE SAME NAME LOGIC: (( AppThemeProvider ))
        ChangeNotifierProvider(create: (_) => LocaleProvider()), // REFACTOR HERE!! LEAVE ALL THIS GUYS WITH THE SAME NAME LOGIC: (( AppLocaleProvider ))
        ChangeNotifierProvider(create: (_) => RestApiProvider()), // REFACTOR HERE!! LEAVE ALL THIS GUYS WITH THE SAME NAME LOGIC: (( AppRestApiProvider ))
      ],
      child: ModularApp(
        module: AppRouteModule(),
        child: const AppMainWidget(),
      ),
    );
  } catch (err, stackTrace) {
    logger.e('Env loading error', error: err, stackTrace: stackTrace);
    return EnvErrorWarningWidget(
      errorMessage: err.toString(),
      onRetry: () => main(),
    );
  }
}
