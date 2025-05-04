import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/app/routes/app_routes_handler.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:provider/provider.dart';

class AppMainWidget extends StatefulWidget {
  const AppMainWidget({super.key});

  @override
  State<AppMainWidget> createState() => _AppMainWidgetState();
}

class _AppMainWidgetState extends State<AppMainWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, appTheme, child) {
        return CupertinoApp(
          title: 'Meu App Cupertino',//ESSE TXT NÃO APARECE NO VISUAL VERIFICAR......
          theme: appTheme.themeData,
          onGenerateRoute: AppRoutesHandler.generateRoute, // Usando nosso método otimizado.
          initialRoute: AppRoutesHandler.home,
          debugShowCheckedModeBanner: false, //############ THE ORIGINAL DEBUG FLAG...
        );
      },
    );
  }
}
