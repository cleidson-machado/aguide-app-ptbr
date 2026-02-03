# Portugal Guide - Guia para Brasileiros 🇧🇷🇵🇹

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

Um aplicativo para auxiliar brasileiros que planejam morar, trabalhar ou viajar em Portugal.

## ✨ Temas Principais

- 📚 Guia sobre como viver em Portugal
- 🏡 Informações sobre moradia e custo de vida
- 💼 Dicas para trabalho e visto de residência
- 🏥 Orientação sobre saúde e sistema público
- 🚍 Transporte e mobilidade em Portugal
- � Costumes e cultura portuguesa
- 🆘 Informações úteis de emergência
- 📅 Atualizações sobre leis e regulamentos

## 🚀 Começando

Este projeto utiliza Flutter para criar uma experiência multiplataforma.

### Pré-requisitos
- Flutter SDK (versão 3.32 ou superior)
- Dart (versão 3.8.0 ou superior)
- Dispositivo ou emulador para teste

### Instalação
1. Clone este repositório
   ```sh
   git clone https://github.com/cleidson-machado/aguide-app-ptbr.git

### Key Concepts of The language and The Project Itself:
# A Widget in Dart is just a class.
# A Widget in Flutter is a class that represents a piece of UI,
and its behavior is defined by extending StatelessWidget, StatefulWidget, or other Flutter widget types.

### A configuration object that describes part of the UI. >>> | Widgets |
“Um widget é um pedaço (ou componente) da interface que descreve como ela deve ser exibida.”

---

## 🛠️ Comandos Úteis de Manutenção

### 🔍 Análise e Qualidade de Código
```bash
# Análise estática do código (verificar erros de linting)
flutter analyze

# Formatação automática do código
dart format .

# Análise sem fatal-infos (apenas erros críticos)
flutter analyze --no-fatal-infos
```

### 📦 Gerenciamento de Dependências
```bash
# Baixar/atualizar dependências
flutter pub get

# Verificar pacotes desatualizados
flutter pub outdated

# Atualizar dependências (respeita constraints do pubspec.yaml)
flutter pub upgrade

# Ver árvore de dependências
flutter pub deps

# Ver dependências compactas
flutter pub deps --style=compact
```

### 🧹 Limpeza de Cache e Build

#### Limpeza Básica
```bash
# Limpar cache de build (recomendado antes de builds importantes)
flutter clean

# Limpar + reinstalar dependências
flutter clean && flutter pub get
```

#### Limpeza Completa (iOS)
```bash
# Limpar Pods do iOS
cd ios && rm -rf Pods Podfile.lock && cd ..

# Limpar DerivedData do Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstalar Pods
cd ios && pod install && cd ..

# Limpeza total iOS
flutter clean && \
cd ios && rm -rf Pods Podfile.lock .symlinks && cd .. && \
flutter pub get && \
cd ios && pod install && cd ..
```

#### Limpeza Completa (Android)
```bash
# Limpar build Gradle
cd android && ./gradlew clean && cd ..

# Limpar cache Gradle
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build

# Limpeza total Android
flutter clean && \
rm -rf android/.gradle android/build android/app/build && \
flutter pub get
```

#### Limpeza Total do Projeto (Todas as Plataformas)
```bash
# Remove TODOS os caches e arquivos gerados
flutter clean && \
rm -rf .dart_tool && \
rm -rf android/.gradle android/build android/app/build && \
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks && \
rm -rf macos/Pods macos/Podfile.lock && \
flutter pub get

# Se estiver no macOS, reinstalar Pods do iOS
cd ios && pod install && cd ..
```

### 🏗️ Build e Execução

#### iOS
```bash
# Build iOS (debug)
flutter build ios --debug

# Build iOS (release)
flutter build ios --release

# Executar em simulador iOS
flutter run -d "iPhone 15 Pro"
```

#### Android
```bash
# Build APK (debug) - útil para testes
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (recomendado para Play Store)
flutter build appbundle --release

# Executar em emulador Android
flutter run -d "Pixel 9 Pro API 35"
```

### ✅ Checklist Pré-Commit (Recomendado)
```bash
# 1. Formatar código
dart format .

# 2. Análise estática
flutter analyze

# 3. Testes (se houver)
flutter test

# 4. Validar build Android
flutter build apk --debug

# 5. Validar build iOS (apenas macOS)
flutter build ios --debug
```

### 🚨 Troubleshooting
```bash
# Se o projeto não compilar, tente na ordem:
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --debug  # ou flutter run

# Se problemas persistirem (iOS):
cd ios && pod deintegrate && pod install && cd ..

# Se problemas persistirem (Android):
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

### 📱 Dispositivos Disponíveis
```bash
# Listar dispositivos/emuladores conectados
flutter devices

# Listar emuladores disponíveis
flutter emulators

# Iniciar um emulador específico
flutter emulators --launch <emulator_id>
```

---

## 📝 Convenções de Código

Este projeto segue as [diretrizes oficiais do Flutter](https://docs.flutter.dev/testing/code-analysis) e [Effective Dart](https://dart.dev/guides/language/effective-dart).

**Principais regras:**
- ✅ Usar `const` sempre que possível
- ✅ Usar `debugPrint()` com `kDebugMode` (nunca `print()`)
- ✅ Widgets Cupertino (estilo iOS) são preferidos
- ✅ Imports desnecessários devem ser removidos
- ✅ APIs deprecated devem ser substituídas imediatamente

Para mais detalhes, consulte [.github/copilot-instructions.md](.github/copilot-instructions.md)