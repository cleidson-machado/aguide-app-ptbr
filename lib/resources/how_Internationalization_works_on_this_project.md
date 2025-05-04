# Project Setup ( Folder Structure )... Review It... TODO

lib/
 ├── core/
 │    ├── config/      # Configuration files (e.g., .env loader)
 │    ├── constants/   # App-wide constants
 │    ├── network/     # API service layer
 │    ├── services/    # Shared services (Analytics, Auth, etc.)
 │    ├── utils/       # Helper functions
 ├── data/
 │    ├── models/      # Data models
 │    ├── repositories/# Repository layer
 ├── modules/
 │    ├── auth/        # Authentication Module
 │    │    ├── view/   # Screens for Auth
 │    │    ├── controller/  # Controller for Auth (MVC Pattern)
 │    │    ├── widgets/ # Custom widgets for Auth
 │    │    ├── services/ # Auth-specific logic
 │    ├── home/        # Home Module (same structure as auth)
 ├── routes/           # Route management
 ├── app.dart          # Main App Widget
 ├── main.dart         # Entry point

## Internationalization  How To
#### Internationalization (i18n) - dependencies

```yaml
dependencies:
  flutter_localizations:s
    sdk: flutter
  intl: any
flutter:
  generate: true

```
##### Create an l10n.yaml file in the root of your project:


```yaml
arb-dir: lib/resources/l10n
template-arb-file: app_en.arb
output-dir: lib/resources/translation
synthetic-package: false
output-localization-file: app_localizations.dart
output-class: AppLocalizations

```

###### Create lib/l10n/app_pt.arb (for Portuguese):

```json
{
  "@@locale": "pt",
  "hello": "Olá",
  "welcome": "Bem-vindo",
  "goodbye": "Adeus",
  "thank_you": "Obrigado",
  "please": "Por favor",
  "yes": "Sim",
  "no": "Não",
  "error": "Erro",
  "loading": "Carregando",
  "success": "Sucesso",
  "languageEnglish": "Inglês",
  "languageSpanish": "Espanhol",
  "languagePortuguese": "Português",
  "languageFrench": "Francês"
}

```

###### Create lib/l10n/app_es.arb (for English):

```yaml
{
  "@@locale": "en",
  "hello": "Hello",
  "welcome": "Welcome",
  "goodbye": "Goodbye",
  "thank_you": "Thank you",
  "please": "Please",
  "yes": "Yes",
  "no": "No",
  "error": "Error",
  "loading": "Loading",
  "success": "Success",
  "languageEnglish": "English",
  "languageSpanish": "Spanish",
  "languagePortuguese": "Portuguese",
  "languageFrench": "French"
}

```
> Use the same example above to the another Languages - "@@locale": "en",
> replace the 'en' or 'pt' to a new language

...
...
##### Modify The ( main.dart )
> Use this code below as reference to add the Internationalization to you code.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
      ],
      home: const HomePage(),
    );
  }
}

```

##### Generate localization files:
```bash
flutter gen-l10n
```

##### Use localization in your app:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.helloWorld);
```
