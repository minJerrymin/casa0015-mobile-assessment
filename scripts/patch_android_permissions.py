from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found. Run: flutter create --platforms=android .')
text = manifest.read_text()
permissions = [
    '<uses-permission android:name="android.permission.INTERNET" />',
    '<uses-permission android:name="android.permission.RECORD_AUDIO" />',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
    '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
]
insert = '\n'.join(permissions) + '\n'
if 'android.permission.RECORD_AUDIO' not in text:
    text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + insert)
else:
    for permission in permissions:
        if permission not in text:
            text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + permission + '\n')
manifest.write_text(text)
print('Android internet, microphone, and location permissions are configured.')
