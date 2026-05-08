param(
  [string]$Version = "v1.0.2"
)

$ErrorActionPreference = "Stop"

Write-Host "Cleaning Flutter project..."
flutter clean

Write-Host "Getting dependencies..."
flutter pub get

Write-Host "Analysing project..."
flutter analyze --no-fatal-infos --no-fatal-warnings

Write-Host "Building Android release APK..."
flutter build apk --release

$releaseDir = "release"
if (!(Test-Path $releaseDir)) {
  New-Item -ItemType Directory -Path $releaseDir | Out-Null
}

$sourceApk = "build/app/outputs/flutter-apk/app-release.apk"
$targetApk = Join-Path $releaseDir "MatchPint-$Version.apk"

Copy-Item $sourceApk $targetApk -Force

Write-Host "APK ready: $targetApk"
