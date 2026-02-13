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

### � Scripts Automatizados de Build Check

```bash
# Verificação completa de build Android
./android_build_check.sh

# Verificação completa de build iOS (Simulador)
./ios_build_check.sh
```

Estes scripts executam:
- ✅ Limpeza de cache
- ✅ Instalação de dependências
- ✅ Análise estática
- ✅ Build debug
- ✅ Validação de ambiente

📚 **Ver comandos detalhados:** [FLUTTER_BUILD_COMMANDS.md](FLUTTER_BUILD_COMMANDS.md)

---

### �🔍 Análise e Qualidade de Código
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

## � Configuração do Google Sign-In

### 🔑 Android SHA-1 Fingerprints

O Google Sign-In no Android requer SHA-1/SHA-256 fingerprints do keystore para autenticação OAuth.

#### Debug SHA-1 (Desenvolvimento)

```bash
# Obter SHA-1 do debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1:"

# Obter SHA-1 e SHA-256
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1:|SHA256:"
```

**SHA-1 Debug Atual:**
```
C5:65:B7:12:FC:07:65:A2:8E:B4:5D:B1:EA:66:AF:81:76:57:28:77
```

#### Release SHA-1 (Produção)

```bash
# Criar keystore de release (se não existir)
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Obter SHA-1 do release keystore
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | grep -E "SHA1:|SHA256:"
```

#### 🍎 iOS - Bundle ID (Não Usa SHA-1)

**Importante:** iOS **NÃO** usa SHA-1 para OAuth. iOS usa:
- ✅ **Bundle ID:** `com.aguide.portugalGuide`
- ✅ **iOS Client ID** do Google Cloud Console
- ✅ **iOS URL Scheme** (gerado automaticamente pelo Google)

```bash
# Verificar Bundle ID do iOS
cat ios/Runner/Info.plist | grep -A 1 "CFBundleIdentifier"
```

### 📚 Onde Usar os SHA-1s

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Selecione seu projeto
3. Vá em: **APIs e Serviços** > **Credenciais**
4. Crie **ID do cliente OAuth 2.0** do tipo **Android**
5. Adicione:
   - **Package name:** `br.com.aguideptbr.portugal_guide`
   - **SHA-1:** Cole o fingerprint apropriado (debug ou release)

**📄 Documentação Completa:**
- [Configuração Google OAuth](x_temp_files/CONFIGURACAO_GOOGLE_OAUTH.md)
- [SHA-1 Fingerprints Detalhados](x_temp_files/ANDROID_SHA1_FINGERPRINTS.md)

---

## �📝 Convenções de Código

Este projeto segue as [diretrizes oficiais do Flutter](https://docs.flutter.dev/testing/code-analysis) e [Effective Dart](https://dart.dev/guides/language/effective-dart).

**Principais regras:**
- ✅ Usar `const` sempre que possível
- ✅ Usar `debugPrint()` com `kDebugMode` (nunca `print()`)
- ✅ Widgets Cupertino (estilo iOS) são preferidos
- ✅ Imports desnecessários devem ser removidos
- ✅ APIs deprecated devem ser substituídas imediatamente

Para mais detalhes, consulte [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## 🏗️ Arquitetura e Padrões do Projeto

### 📂 Estrutura de Pastas (MVVM + DDD)

Este projeto utiliza **MVVM (Model-View-ViewModel)** com **DDD (Domain-Driven Design)**, seguindo a **Linguagem Ubíqua** para nomenclatura.

```
lib/
├── app/
│   ├── core/                      # Código compartilhado do núcleo (RESERVADO)
│   │   ├── config/                # Injeção de dependência, rotas
│   │   └── constants/             # Constantes globais
│   └── app_custom_main_widget.dart
├── features/                      # Funcionalidades por domínio (DDD)
│   ├── auth_credentials/          # Autenticação via API REST (email/senha)
│   ├── auth_google/               # Autenticação OAuth Google
│   ├── main_contents/             # Conteúdos principais
│   ├── user/                      # Gerenciamento de usuário
│   └── [outras features...]
├── resources/                     # Recursos globais (i18n, assets)
├── util/                          # Utilitários compartilhados
└── widgets/                       # Widgets reutilizáveis
```

### 🔐 Padrão de Nomenclatura para Autenticação

**Importante:** A palavra **"core"** é EXCLUSIVA para `lib/app/core/` (código compartilhado).

**Features de autenticação seguem o padrão:**

```
lib/features/
├── auth_credentials/      # Autenticação própria (API REST - email/senha)
├── auth_google/           # OAuth Google
├── auth_facebook/         # OAuth Facebook (futuro)
├── auth_linkedin/         # OAuth LinkedIn (futuro)
├── auth_apple/            # Sign in with Apple (futuro)
```

**Por que `auth_credentials`?**
- ✅ Indica claramente que é autenticação por credenciais (email/senha)
- ✅ Diferencia de autenticações externas (OAuth/Social)
- ✅ Segue padrão DDD (termo do domínio, não técnico)
- ✅ Escalável para adicionar novos providers sem conflito

**Exemplo de estrutura interna:**
```
lib/features/auth_credentials/
├── auth_credentials_controller.dart
├── auth_credentials_login_view_model.dart
├── auth_credentials_model.dart
├── auth_credentials_service.dart
└── screens/
    ├── auth_credentials_login_screen.dart
    ├── auth_credentials_register_screen.dart
    └── auth_credentials_forgot_pass_screen.dart
```

### 📋 Camadas da Arquitetura MVVM

1. **View (Screens)**: Interface do usuário (widgets Cupertino)
2. **ViewModel**: Lógica de negócio e gerenciamento de estado (`ChangeNotifier`)
3. **Model**: Representação de dados (classes imutáveis com `fromJson`/`toJson`)
4. **Service**: Camada de dados (requisições HTTP, cache, etc.)

---