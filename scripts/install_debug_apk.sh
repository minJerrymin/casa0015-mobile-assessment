#!/usr/bin/env bash
set -euo pipefail

bash scripts/build_debug_apk.sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk

echo "Installed MatchPint debug APK. You can now disconnect USB and open it from the phone launcher."
