import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  const cancelLabels = {
    'en': 'Cancel',
    'pt': 'Cancelar',
    'es': 'Cancelar',
    'fr': 'Annuler',
  };

  test('Google Fonts retains the font families used by the app', () {
    final fonts = GoogleFonts.asMap();
    expect(fonts, contains('Lato'));
    expect(fonts, contains('Roboto'));
  });

  test('theme changes notify listeners and preserve Cupertino styling', () {
    final theme = AppThemeProvider();
    addTearDown(theme.dispose);
    var notifications = 0;
    theme.addListener(() => notifications++);

    expect(theme.isDarkMode, isFalse);
    expect(theme.themeData.brightness, Brightness.light);
    theme.toggleTheme();
    expect(theme.isDarkMode, isTrue);
    expect(theme.themeData.brightness, Brightness.dark);
    expect(theme.themeData.primaryColor, CupertinoColors.systemBlue);
    theme.toggleTheme();
    expect(theme.themeData.brightness, Brightness.light);
    expect(notifications, 2);
  });

  test('locale changes preserve supported languages and notify listeners', () {
    final locale = AppLocaleProvider();
    addTearDown(locale.dispose);
    expect(cancelLabels.keys, contains(locale.currentLocale.languageCode));
    var notifications = 0;
    locale.addListener(() => notifications++);
    for (final language in cancelLabels.keys) {
      locale.changeLocale(Locale(language));
      expect(locale.currentLocale, Locale(language));
    }
    expect(notifications, cancelLabels.length);
  });

  for (final entry in cancelLabels.entries) {
    for (final darkMode in [false, true]) {
      testWidgets('${entry.key} Cupertino localization and skeleton rendering '
          'in ${darkMode ? 'dark' : 'light'} mode', (tester) async {
        final theme = AppThemeProvider();
        addTearDown(theme.dispose);
        if (darkMode) {
          theme.toggleTheme();
        }

        for (final loading in [true, false]) {
          await tester.pumpWidget(
            CupertinoApp(
              theme: theme.themeData,
              locale: Locale(entry.key),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) => CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(AppLocalizations.of(context)!.error),
                  ),
                  child: SafeArea(
                    child: Skeletonizer(
                      enabled: loading,
                      child: Center(
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text(entry.value), findsOneWidget);
          expect(find.byType(CupertinoPageScaffold), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
