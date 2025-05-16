import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:portugal_guide/app/app_custom_main_widget.dart';
import 'package:portugal_guide/app/rouute_main_stuff/app_module.dart';
import 'package:portugal_guide/app/theme/app_theme_provider_full.dart';
import 'package:portugal_guide/resources/locale_provider.dart';
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
      child: ModularApp(module: AppModule(), child: const AppMainWidget())
    ),
  );
}