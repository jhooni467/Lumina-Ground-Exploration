#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/app"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || fail "Falta Node.js 22 o superior."
command -v npm >/dev/null 2>&1 || fail "Falta npm (se instala junto con Node.js)."
command -v python3 >/dev/null 2>&1 || fail "Falta Python 3, necesario para ajustar los archivos Android."

NODE_MAJOR="$(node -p 'Number(process.versions.node.split(".")[0])')"
[[ "$NODE_MAJOR" =~ ^[0-9]+$ ]] || fail "No pude detectar la versión de Node.js."
(( NODE_MAJOR >= 22 )) || fail "Capacitor 8 requiere Node.js 22 o superior. Versión detectada: $(node --version)."

if [[ -n "${JAVA_HOME:-}" ]]; then
  [[ -x "$JAVA_HOME/bin/java" ]] || fail "JAVA_HOME no apunta a una instalación válida de Java: $JAVA_HOME"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
command -v java >/dev/null 2>&1 || fail "No encuentro Java. Usa el JDK incluido con Android Studio y configura JAVA_HOME o PATH."

if [[ -z "${ANDROID_HOME:-}" && -n "${ANDROID_SDK_ROOT:-}" ]]; then
  ANDROID_HOME="$ANDROID_SDK_ROOT"
fi
[[ -n "${ANDROID_HOME:-}" ]] || fail "Define ANDROID_HOME o ANDROID_SDK_ROOT con la ruta del Android SDK."
[[ -d "$ANDROID_HOME" ]] || fail "No existe la carpeta del Android SDK: $ANDROID_HOME"
export ANDROID_HOME
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

[[ -f "$ROOT_DIR/index.html" ]] || fail "No encuentro index.html junto a build-android.sh."

mkdir -p "$APP_DIR/www"
cd "$APP_DIR"

# Conserva package.json y el proyecto Android entre compilaciones.
if [[ ! -f package.json ]]; then
  npm init -y
fi

npm install --no-audit --no-fund \
  three@0.128.0 \
  @capacitor/core@8 \
  @capacitor/cli@8 \
  @capacitor/android@8 \
  @capacitor/app@8

THREE_FILE="node_modules/three/build/three.min.js"
[[ -f "$THREE_FILE" ]] || fail "No se encontró Three.js después de instalar las dependencias."
cp "$THREE_FILE" www/three.min.js

# En el APK, Three.js se carga localmente y no desde una CDN.
sed 's#https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js#three.min.js#g' \
  "$ROOT_DIR/index.html" > www/index.html
grep -q 'src="three.min.js"' www/index.html || fail "No se pudo configurar Three.js localmente."

if [[ ! -f capacitor.config.json && ! -f capacitor.config.ts ]]; then
  npx cap init Lumina com.lumina.groundexploration --web-dir www
fi

if [[ ! -d android ]]; then
  npx cap add android
fi

MANIFEST="android/app/src/main/AndroidManifest.xml"
STYLES="android/app/src/main/res/values/styles.xml"
[[ -f "$MANIFEST" ]] || fail "No encuentro el AndroidManifest.xml generado por Capacitor."
[[ -f "$STYLES" ]] || fail "No encuentro styles.xml generado por Capacitor."

# Ajustes idempotentes: se pueden repetir sin duplicar atributos ni estilos.
python3 - "$MANIFEST" "$STYLES" <<'PY'
import re
import sys
from pathlib import Path

manifest_path, styles_path = map(Path, sys.argv[1:3])
manifest = manifest_path.read_text(encoding="utf-8")
activity_re = re.compile(r"<activity\b[^>]*>", re.IGNORECASE | re.DOTALL)
activities = list(activity_re.finditer(manifest))
if not activities:
    raise SystemExit("No se encontró ninguna etiqueta <activity> en AndroidManifest.xml.")

# Prioriza MainActivity; si el template cambia, usa la primera actividad declarada.
match = next((m for m in activities if "MainActivity" in m.group(0)), activities[0])
tag = match.group(0)
orientation_re = re.compile(r'(\bandroid:screenOrientation\s*=\s*)(["\'])[^"\']*\2')
if orientation_re.search(tag):
    tag = orientation_re.sub(r'\1"sensorLandscape"', tag)
else:
    tag = tag[:-1].rstrip() + ' android:screenOrientation="sensorLandscape">'
manifest = manifest[:match.start()] + tag + manifest[match.end():]
manifest_path.write_text(manifest, encoding="utf-8")

theme_match = re.search(r'\bandroid:theme\s*=\s*["\']@style/([^"\']+)', tag)
theme_name = theme_match.group(1) if theme_match else "AppTheme.NoActionBar"
styles = styles_path.read_text(encoding="utf-8")
style_re = re.compile(
    r'(<style\b(?=[^>]*\bname\s*=\s*["\']' + re.escape(theme_name) + r'["\'])[^>]*>)(.*?)(</style\s*>)',
    re.IGNORECASE | re.DOTALL,
)
style_match = style_re.search(styles)
if not style_match:
    raise SystemExit(f"No se encontró el estilo {theme_name!r} en styles.xml.")
body = style_match.group(2)
for item_name in ("android:windowFullscreen", "android:windowLayoutInDisplayCutoutMode"):
    body = re.sub(
        r'\s*<item\s+name=["\']' + re.escape(item_name) + r'["\']>.*?</item\s*>',
        "",
        body,
        flags=re.IGNORECASE | re.DOTALL,
    )
body = body.rstrip() + (
    '\n        <item name="android:windowFullscreen">true</item>'
    '\n        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>\n    '
)
styles = styles[:style_match.start(2)] + body + styles[style_match.end(2):]
styles_path.write_text(styles, encoding="utf-8")
PY

npx cap sync android
cd android
chmod +x ./gradlew
./gradlew --no-daemon assembleDebug

APK="$APP_DIR/android/app/build/outputs/apk/debug/app-debug.apk"
[[ -f "$APK" ]] || fail "Gradle terminó, pero no apareció el APK esperado: $APK"
printf '\nAPK generado correctamente:\n%s\n' "$APK"
