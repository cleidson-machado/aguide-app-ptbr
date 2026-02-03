import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portugal_guide/app/app_custom_main_widget.dart';
import 'package:portugal_guide/app/core/config/injector.dart'; // ##### dependency_injector ######: Importa o Service Locator!!
import 'package:portugal_guide/app/helpers/env_error_warning_widget.dart';
import 'package:portugal_guide/app/routing/app_route_module.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

final logger = Logger(); // Instância global do Logger
const String envFileName = ".env.dev";

// ########### Ignora erros de certificado SSL... deixe aqui apenas para testes locais, não use em produção! --- INICO
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
// ########### Ignora erros de certificado SSL... deixe aqui apenas para testes locais, não use em produção! --- FIM

void main() {
  HttpOverrides.global =
      MyHttpOverrides(); // Ignora erros de certificado SSL... deixe aqui apenas para testes locais, não use em produção!
  WidgetsFlutterBinding.ensureInitialized(); //USO CORRETO? YES!!!!!

  setupDependencies(); // <-- ##### dependency_injector ######: Importa o Service Locator!!

  _initializeApp().then((app) => runApp(app));
}

Future<Widget> _initializeApp() async {
  try {
    await dotenv
        .load(fileName: envFileName)
        .timeout(
          const Duration(seconds: 5),
          onTimeout:
              () =>
                  throw TimeoutException('Timeout while loading $envFileName'),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppThemeProvider(),
        ), // Manages the app's visual theme (light/dark mode) across the entire application.
        ChangeNotifierProvider(
          create: (_) => AppLocaleProvider(),
        ), // Manages the app's language, defaulting to the device's locale on startup.
      ],
      child: ModularApp(
        module: AppRouteModule(),
        child:
            const AppMainWidget(), // Verifiy if this is the correct usage of AppMainWidget because we have internacionalization stuff in side it, so it should be the main widget of the app.
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
