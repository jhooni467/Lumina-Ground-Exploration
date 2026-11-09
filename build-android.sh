#!/usr/bin/env bash
# Genera el APK de Lumina con Capacitor. Ejecútalo en tu PC junto a index.html
# Requisitos: Node 18+, JDK 17, Android SDK (variable ANDROID_HOME) y conexión a internet.
set -e
cd "$(dirname "$0")"
command -v node >/dev/null || { echo "Falta Node.js"; exit 1; }
command -v java >/dev/null || { echo "Falta JDK 17"; exit 1; }
[ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ] || { echo "Define ANDROID_HOME (Android SDK)"; exit 1; }
rm -rf app && mkdir -p app/www && cd app
npm init -y >/dev/null
npm i three@0.128.0 @capacitor/core @capacitor/cli @capacitor/android @capacitor/app
cp node_modules/three/build/three.min.js www/three.min.js
# copia del juego que usa three.js local (sin internet)
sed 's#https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js#three.min.js#' ../index.html > www/index.html
grep -q 'src="three.min.js"' www/index.html || { echo "No se pudo apuntar three.js a local"; exit 1; }
npx cap init Lumina com.lumina.groundexploration --web-dir www
npx cap add android
M=android/app/src/main/AndroidManifest.xml
sed -i 's#<activity #<activity android:screenOrientation="portrait" #' "$M"
npx cap sync android
cd android && chmod +x gradlew && ./gradlew assembleDebug
echo "APK: $(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "Para AAB firmado: ./gradlew bundleRelease (necesita tu keystore)"
