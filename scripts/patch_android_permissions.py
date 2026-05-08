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

manifest_tag = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
for permission in permissions:
    if permission not in text:
        text = text.replace(manifest_tag, manifest_tag + '\n' + permission)

queries = '''<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="geo" />
    </intent>
</queries>'''
if '<queries>' not in text:
    text = text.replace('<application', queries + '\n    <application')

manifest.write_text(text)

# Replace the default Android launcher icon with the MatchPint splash/logo mark.
# Run this after `flutter create --platforms=android .` so the Android res folders exist.
launcher_source_dir = Path('assets/launcher')
icon_map = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}
for density in icon_map:
    target_dir = Path(f'android/app/src/main/res/mipmap-{density}')
    if target_dir.exists():
        source = launcher_source_dir / f'ic_launcher_{density}.png'
        round_source = launcher_source_dir / f'ic_launcher_round_{density}.png'
        if source.exists():
            (target_dir / 'ic_launcher.png').write_bytes(source.read_bytes())
        if round_source.exists():
            (target_dir / 'ic_launcher_round.png').write_bytes(round_source.read_bytes())
        foreground_source = launcher_source_dir / f'ic_launcher_foreground_{density}.png'
        if foreground_source.exists():
            (target_dir / 'ic_launcher_foreground.png').write_bytes(foreground_source.read_bytes())

print('Android permissions, map intent queries, and MatchPint launcher icon are configured.')
