# Flutter Useful Commands Guide

## Basic Development Commands

### Run App in Debug Mode
```bash
# Run on iOS emulator (current setup)
flutter run

# Run with verbose output (for debugging)
flutter run -v

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Run App with Hot Reload Features
```bash
# Standard run (supports hot reload with 'r' key)
flutter run

# Hot reload only - after running, press 'r' in terminal
# Hot restart - press 'R' in terminal

# Disable code signing issues on iOS
flutter run --no-code-sign
```

---

## iOS Commands (For Your Current Setup)

### Run on iOS Emulator
```bash
# Run on iOS simulator
flutter run -d <simulator_id>

# Find available iOS simulators
xcrun simctl list devices

# Run on all connected iOS simulators
flutter run -d all
```

### Build iOS App for Release
```bash
# Build iOS app (generates .app)
flutter build ios

# Build iOS app for release
flutter build ios --release

# Build and generate IPA (for App Store)
flutter build ipa --release

# IPA will be generated at: build/ios/ipa/
```

### Clean iOS Build
```bash
flutter clean
flutter pub get
flutter run
```

---

## Android Commands

### Run on Android Emulator
```bash
# List Android devices/emulators
flutter devices

# Run on Android emulator
flutter run -d <emulator_id>

# Run on all connected Android devices
flutter run -d all
```

### Build APK
```bash
# Build APK for testing (debug)
flutter build apk

# Build APK for release
flutter build apk --release

# Build split APKs (smaller size, architecture-specific)
flutter build apk --split-per-abi --release

# APK files will be at: build/app/outputs/flutter-apk/
```

### Build AAB (Android App Bundle - for Play Store)
```bash
# Build AAB for Google Play Store
flutter build appbundle --release

# AAB will be at: build/app/outputs/bundle/release/
```

---

## Project Setup & Dependencies

### Get Dependencies
```bash
flutter pub get
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Check Flutter Environment
```bash
flutter doctor

# Detailed report
flutter doctor -v
```

### Clean Project
```bash
flutter clean
```

---

## Code Generation & Build Runner

### Generate Code (if using build_runner)
```bash
flutter pub run build_runner build

# Watch mode (rebuilds on changes)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

---

## Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with verbose output
flutter test -v
```

---

## Performance & Analysis

### Profile App
```bash
# Run in profile mode (optimized for performance testing)
flutter run --profile
```

### Release Mode
```bash
# Run in release mode (fully optimized)
flutter run --release
```

### Check Code Issues
```bash
# Analyze code for errors
flutter analyze

# Check for format issues
dart format lib/ --set-exit-if-changed
```

---

## Useful Keyboard Shortcuts During `flutter run`

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `h` | Show help |
| `q` | Quit |
| `w` | Toggle debug widget inspector |
| `p` | Toggle performance overlay |
| `L` | Toggle platform log filter |

---

## Common Development Workflow

```bash
# 1. Start fresh
flutter clean
flutter pub get

# 2. Run with verbose for debugging
flutter run -v

# 3. Make code changes, use hot reload (press 'r')

# 4. When ready to test on device
flutter build apk --release        # For Android
flutter build ipa --release        # For iOS
```

---

## Notes

- **For iOS**: Requires Xcode and can take longer to build
- **For Android**: Requires Android SDK
- Use `flutter doctor` to verify your setup is complete
- Environment file (`.env.dev`) is loaded during app initialization
- Check logs with `flutter logs` in another terminal while running
