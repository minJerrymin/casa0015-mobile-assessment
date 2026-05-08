$manifest = "android/app/src/main/AndroidManifest.xml"
if (!(Test-Path $manifest)) {
  Write-Error "AndroidManifest.xml not found. Run: flutter create --platforms=android ."
  exit 1
}
$text = Get-Content $manifest -Raw
$manifestTag = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
$manifestTag = $manifestTag -replace '\\"', '"'
$permissions = @(
  '<uses-permission android:name="android.permission.INTERNET" />',
  '<uses-permission android:name="android.permission.RECORD_AUDIO" />',
  '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
  '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'
) | ForEach-Object { $_ -replace '\\"', '"' }
foreach ($permission in $permissions) {
  if ($text -notlike "*$permission*") {
    $text = $text -replace [regex]::Escape($manifestTag), "$manifestTag`n$permission"
  }
}
$queries = @'
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="geo" />
    </intent>
</queries>
'@
$queries = $queries -replace '\\"', '"'
if ($text -notlike "*<queries>*") {
  $text = $text -replace '<application', "$queries`n    <application"
}
Set-Content $manifest $text

# Replace the default Android launcher icon with the MatchPint splash/logo mark.
# Run this after `flutter create --platforms=android .` so the Android res folders exist.
$densities = @('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi')
foreach ($density in $densities) {
  $targetDir = "android/app/src/main/res/mipmap-$density"
  $source = "assets/launcher/ic_launcher_$density.png"
  $roundSource = "assets/launcher/ic_launcher_round_$density.png"
  if (Test-Path $targetDir) {
    $foregroundSource = "assets/launcher/ic_launcher_foreground_$density.png"
    if (Test-Path $source) { Copy-Item $source "$targetDir/ic_launcher.png" -Force }
    if (Test-Path $roundSource) { Copy-Item $roundSource "$targetDir/ic_launcher_round.png" -Force }
    if (Test-Path $foregroundSource) { Copy-Item $foregroundSource "$targetDir/ic_launcher_foreground.png" -Force }
  }
}

Write-Host "Android permissions, map intent queries, and MatchPint launcher icon are configured."
