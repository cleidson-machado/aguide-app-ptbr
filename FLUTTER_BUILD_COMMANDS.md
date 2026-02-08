# 🛠️ Comandos Úteis de Build Flutter

**Projeto:** aguide-app-ptbr  
**Plataformas:** Android + iOS  
**Última atualização:** 08/02/2026

---

## 📱 Android Build Commands

### Debug Builds

```bash
# Build APK Debug (recomendado para testes)
flutter build apk --debug

# Build APK Debug com splits por ABI (menor tamanho)
flutter build apk --debug --split-per-abi

# Build APK Debug sem R8 shrinking
flutter build apk --debug --no-shrink
```

### Release Builds

```bash
# Build APK Release (produção)
flutter build apk --release

# Build APK Release com splits (recomendado)
flutter build apk --release --split-per-abi

# Build App Bundle (Google Play Store - recomendado)
flutter build appbundle --release

# Build com obfuscação (segurança extra)
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Verificação de Build

```bash
# Listar dispositivos Android conectados
flutter devices

# Instalar APK em dispositivo conectado
flutter install

# Build e rodar direto no dispositivo
flutter run --release
```

---

## 🍎 iOS Build Commands

### Debug Builds (Simulador)

```bash
# Build para simulador (NÃO requer certificado)
flutter build ios --debug --simulator

# Build com verbose para debug
flutter build ios --debug --simulator --verbose

# Build com codesign desabilitado
flutter build ios --debug --no-codesign
```

### Debug Builds (Dispositivo Físico)

```bash
# Build para dispositivo físico (REQUER certificado)
flutter build ios --debug

# Build com profile específico
flutter build ios --debug --profile

# Build com verbose para troubleshooting
flutter build ios --debug --verbose
```

### Release Builds

```bash
# Build IPA para distribuição (App Store / TestFlight)
flutter build ipa --release

# Build IPA com obfuscação
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols

# Build com método de exportação específico
flutter build ipa --release --export-method app-store

# Métodos de exportação disponíveis:
# - app-store (App Store / TestFlight)
# - ad-hoc (distribuição limitada)
# - development (desenvolvimento)
# - enterprise (empresas)
```

### Verificação de Build

```bash
# Listar simuladores iOS disponíveis
xcrun simctl list devices available | grep iPhone

# Abrir simulador
open -a Simulator

# Build e rodar no simulador
flutter run -d "iPhone 16 Pro"

# Listar todos os dispositivos (físicos + simuladores)
flutter devices
```

---

## 🧪 Comandos de Verificação de Saúde do Build

### Limpeza e Preparação

```bash
# Limpar cache do Flutter (recomendado antes de builds importantes)
flutter clean

# Reinstalar dependências
flutter pub get

# Verificar problemas no ambiente
flutter doctor -v

# Análise estática do código
flutter analyze

# Formatação do código
dart format .
```

### Verificação de Dependências

```bash
# Verificar dependências desatualizadas
flutter pub outdated

# Atualizar dependências (com cuidado!)
flutter pub upgrade

# Verificar dependências não utilizadas
flutter pub deps
```

### Testes

```bash
# Executar todos os testes
flutter test

# Executar testes com cobertura
flutter test --coverage

# Executar testes de integração
flutter drive --target=test_driver/app.dart
```

---

## 🔍 Troubleshooting e Debug

### Android

```bash
# Verificar configuração Gradle
cd android && ./gradlew tasks

# Limpar build Gradle
cd android && ./gradlew clean

# Build Gradle com stacktrace
cd android && ./gradlew assembleDebug --stacktrace

# Verificar versões do SDK
flutter doctor --android-licenses
```

### iOS

```bash
# Limpar build do Xcode
rm -rf ios/build

# Limpar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reinstalar CocoaPods
cd ios && pod deintegrate && pod install

# Atualizar repositórios de pods
cd ios && pod repo update && pod install

# Abrir projeto no Xcode
open ios/Runner.xcworkspace
```

---

## 📊 Verificação de Tamanho de Build

### Android

```bash
# Verificar tamanho do APK
ls -lh build/app/outputs/flutter-apk/

# Analisar conteúdo do APK (requer Android SDK)
$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer -h
```

### iOS

```bash
# Verificar tamanho do IPA
ls -lh build/ios/ipa/

# Verificar tamanho do app
du -sh build/ios/iphonesimulator/Runner.app
```

---

## 🚀 Scripts de Verificação Rápida

### Verificação Completa (Android + iOS)

```bash
#!/bin/bash
echo "🧹 Limpando projeto..."
flutter clean

echo "📦 Instalando dependências..."
flutter pub get

echo "🔍 Analisando código..."
flutter analyze

echo "🤖 Build Android..."
flutter build apk --debug

echo "🍎 Build iOS..."
flutter build ios --debug --simulator

echo "✅ Verificação completa!"
```

### Verificação Rápida

```bash
#!/bin/bash
flutter analyze && \
flutter build apk --debug && \
flutter build ios --debug --simulator
```

---

## 📋 Checklist de Build Saudável

### Antes de Commit

- [ ] `flutter analyze` → 0 errors, < 5 warnings
- [ ] `flutter test` → Todos os testes passando
- [ ] `dart format .` → Código formatado
- [ ] `flutter clean && flutter pub get` → Dependências limpas
- [ ] `flutter build apk --debug` → Build Android OK
- [ ] `flutter build ios --debug --simulator` → Build iOS OK

### Antes de Release

- [ ] Versão atualizada em `pubspec.yaml`
- [ ] Changelog atualizado
- [ ] Testes de integração executados
- [ ] Build release testado em dispositivos físicos
- [ ] Assets e recursos validados
- [ ] Certificados e signing configurados
- [ ] `flutter build apk --release --split-per-abi` → Android OK
- [ ] `flutter build ipa --release` → iOS OK

---

## 🔗 Recursos Úteis

- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Android Deployment](https://docs.flutter.dev/deployment/android)
- [iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Obfuscating Dart Code](https://docs.flutter.dev/deployment/obfuscate)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

---

## 💡 Dicas Importantes

### Performance

- Use `--release` para medir performance real
- Habilite `--split-per-abi` para reduzir tamanho do APK
- Use obfuscação (`--obfuscate`) em produção para segurança

### Debugging

- Use `--verbose` para ver logs detalhados
- Mantenha `flutter doctor` sempre verde
- Execute `flutter clean` se houver problemas estranhos

### Certificados iOS

- Simulador → **NÃO** requer certificado
- Dispositivo físico → **REQUER** certificado
- App Store → **REQUER** Apple Developer Program

### Compatibilidade

- Teste em múltiplos dispositivos/emuladores
- Valide em diferentes versões de Android/iOS
- Execute builds em ambiente limpo antes de release

---

**Scripts Automatizados:**
- [android_build_check.sh](android_build_check.sh) - Verificação Android
- [ios_build_check.sh](ios_build_check.sh) - Verificação iOS
