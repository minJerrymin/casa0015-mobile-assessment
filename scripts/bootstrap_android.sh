#!/usr/bin/env bash
set -e
flutter create --platforms=android .
flutter pub get
dart run flutter_native_splash:create
flutter run
