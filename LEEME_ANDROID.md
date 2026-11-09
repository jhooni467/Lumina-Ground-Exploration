# Lumina en Android (APK)

El juego es web (Three.js), así que se empaqueta con Capacitor. **Estos pasos no se han ejecutado todavía: el APK no está compilado ni probado.**

1. Instala Node 18+, JDK 17 y Android Studio (SDK). Define `ANDROID_HOME`.
2. Pon `index.html` y `build-android.sh` en la misma carpeta.
3. Ejecuta: `./build-android.sh`
4. El APK queda en `app/android/app/build/outputs/apk/debug/app-debug.apk`.
5. Instálalo: `adb install -r app-debug.apk` (o copia el archivo al móvil y ábrelo).

Detalles: pantalla en vertical, three.js local (funciona sin internet), botón Atrás abre el menú, el progreso se guarda al pausar.
AAB para Play Store: `cd app/android && ./gradlew bundleRelease` (requiere firmar con tu keystore).
Si algo falla, copia el error y lo corrijo.
