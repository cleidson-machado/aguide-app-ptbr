import 'dart:ui';

import 'package:flutter/cupertino.dart';

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