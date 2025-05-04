import 'package:flutter/cupertino.dart';

class AppTheme with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  CupertinoThemeData get themeData => _isDarkMode
      ? const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor: CupertinoColors.darkBackgroundGray,
          scaffoldBackgroundColor: CupertinoColors.black,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 16,
              color: CupertinoColors.white,
            ),
          ),
        )
      : const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor: CupertinoColors.white,
          scaffoldBackgroundColor: CupertinoColors.extraLightBackgroundGray,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 16,
              color: CupertinoColors.black,
            ),
          ),
        );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
