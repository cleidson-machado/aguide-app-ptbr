import 'dart:ui';
import 'package:flutter/cupertino.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portugal_guide/app/app_custom_main_widget.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //WidgetsFlutterBinding.ensureInitialized(); //############# Function to ensure Flutter is initialized before loading the .ENV file!!...
  //await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppTheme()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const AppMainWidget(),
    ),
  );
}

// Adicione esta classe para gerenciar o idioma
class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale;

  LocaleProvider() : _currentLocale = _getDeviceLocale();

  Locale get currentLocale => _currentLocale;

  static Locale _getDeviceLocale() {
    Locale deviceLocale = PlatformDispatcher.instance.locale;
    const supportedLocales = [
      Locale('en', ''),
      Locale('es', ''),
      Locale('pt', ''),
      Locale('fr', ''),
    ];

    return supportedLocales.contains(Locale(deviceLocale.languageCode))
        ? Locale(deviceLocale.languageCode)
        : const Locale('en', '');
  }

  void changeLocale(Locale newLocale) {
    _currentLocale = newLocale;
    notifyListeners();
  }
}