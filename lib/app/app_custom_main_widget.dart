import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
// import 'package:portugal_guide/app/routes/app_routes_handler.dart'; //#######>>>> USED to CREATE A SIMPLE LINK TO OTHER PAGE.....
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
import 'package:portugal_guide/resources/translation/app_localizations.dart';
import 'package:provider/provider.dart';

class AppMainWidget extends StatefulWidget {
  const AppMainWidget({super.key});

  @override
  State<AppMainWidget> createState() => _AppMainWidgetState();
}

class _AppMainWidgetState extends State<AppMainWidget> {

  final isDev = EnvKeyHelperConfig.label.toUpperCase() == 'DEV'; // TEST_env

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, appTheme, child) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return CupertinoApp.router(
              title: 'Meu App Cupertino',
              theme: appTheme.themeData,
              routerConfig: Modular.routerConfig,
              // onGenerateRoute: AppRoutesHandler.generateRoute,
              // initialRoute: AppRoutesHandler.home,
              debugShowCheckedModeBanner: isDev ? true : false,
              
              // Adicionando suporte a internacionalização
              locale: localeProvider.currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English
                Locale('es', ''), // Spanish
                Locale('pt', ''), // Portuguese
                Locale('fr', ''), // French
              ],
              
            );
          },
        );
      },
    );
  }
}