import 'package:flutter/cupertino.dart';

class AppThemeProvider with ChangeNotifier {
  CupertinoThemeData _themeData = const CupertinoThemeData(brightness: Brightness.light);

  CupertinoThemeData get themeData => _themeData;

  void toggleTheme() {
    _themeData = _themeData.brightness == Brightness.light
        ? const CupertinoThemeData(brightness: Brightness.dark)
        : const CupertinoThemeData(brightness: Brightness.light);
    notifyListeners();
  }
}
