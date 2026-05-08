$manifest = "android/app/src/main/AndroidManifest.xml"
if (!(Test-Path $manifest)) {
  Write-Error "AndroidManifest.xml not found. Run: flutter create --platforms=android ."
  exit 1
}
$text = Get-Content $manifest -Raw
$permissions = @(
  '<uses-permission android:name="android.permission.INTERNET" />',
  '<uses-permission android:name="android.permission.RECORD_AUDIO" />',
  '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
  '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'
)
foreach ($permission in $permissions) {
  if ($text -notlike "*$permission*") {
    $text = $text -replace '<manifest xmlns:android="http://schemas.android.com/apk/res/android">', "<manifest xmlns:android=`"http://schemas.android.com/apk/res/android`">`n$permission"
  }
}
Set-Content $manifest $text
Write-Host "Android internet, microphone, and location permissions are configured."
