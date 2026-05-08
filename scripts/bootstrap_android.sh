#!/usr/bin/env bash
set -euo pipefail

flutter create --platforms=android .
python3 scripts/patch_android_permissions.py
flutter pub get
dart run flutter_native_splash:create

echo "MatchPint is ready. Run: flutter run --debug"
