#!/bin/bash

echo ""
echo "🚀 Starting APK build process..."

ROOT_DIR=$(pwd)
FAILED_BUILDS=()

# Find all folders containing pubspec.yaml
PROJECTS=$(find . -type f -name "pubspec.yaml")

for PROJECT_FILE in $PROJECTS; do
  PROJECT_DIR=$(dirname "$PROJECT_FILE")
  echo ""
  echo "🔍 Building project in: $PROJECT_DIR"

  cd "$PROJECT_DIR" || continue

  echo "📦 Running: flutter build apk --release"
  flutter build apk --release

  if [ $? -ne 0 ]; then
    echo "❌ Build failed in: $PROJECT_DIR"
    FAILED_BUILDS+=("$PROJECT_DIR")
  else
    APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
      APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
      echo ""
      echo "📋 === Build Summary 1 ==="
      echo "✅ APK compilation OK! in this PATH:: $APK_PATH ($APK_SIZE)"
    else
      echo "⚠️ Build succeeded but APK not found."
      FAILED_BUILDS+=("$PROJECT_DIR (APK missing)")
    fi
  fi

  # Return to root directory
  cd "$ROOT_DIR" || exit
done

echo ""
echo "📋 === Build Summary 2 ==="
if [ ${#FAILED_BUILDS[@]} -eq 0 ]; then
  echo "🎉 All projects built successfully!"
  echo ""
else
  echo "❌ The following projects failed to build:"
  for FAILED in "${FAILED_BUILDS[@]}"; do
    echo "   - $FAILED"
  done
fi
