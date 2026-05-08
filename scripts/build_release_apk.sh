#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.0.2}"

echo "Cleaning Flutter project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Analysing project..."
flutter analyze --no-fatal-infos --no-fatal-warnings

echo "Building Android release APK..."
flutter build apk --release

mkdir -p release
cp build/app/outputs/flutter-apk/app-release.apk "release/MatchPint-${VERSION}.apk"

echo "APK ready: release/MatchPint-${VERSION}.apk"
