# Lumina en Android (APK)

El juego sigue siendo una aplicación web basada en Three.js. Este script la empaqueta como APK con Capacitor 8.

## Requisitos

- Node.js **22 o superior** y npm.
- Android Studio **2025.2.1 o superior**.
- Android SDK instalado desde Android Studio (API 24 o superior, junto con Android SDK Build-Tools y Command-line Tools).
- Java disponible para Gradle. Android Studio incluye el JDK compatible; si la terminal no encuentra `java`, configura `JAVA_HOME` para apuntar al JDK incluido en tu instalación de Android Studio.
- Bash y Python 3.
- Conexión a internet durante la primera compilación para descargar dependencias.

## Compilar el APK

1. Coloca `index.html` y `build-android.sh` en la misma carpeta.
2. Configura `ANDROID_HOME` o `ANDROID_SDK_ROOT` con la ruta del Android SDK.
3. En una terminal, entra en esa carpeta y ejecuta:

   ```bash
   ./build-android.sh
   ```

4. El APK de depuración se genera en:

   `app/android/app/build/outputs/apk/debug/app-debug.apk`

El script conserva la carpeta `app/` entre compilaciones: actualiza los archivos web y sincroniza Capacitor sin borrar el proyecto Android existente. En la primera ejecución crea esa estructura automáticamente.

## Detalles

- El juego se configura en orientación horizontal y pantalla completa.
- Three.js se copia dentro del APK y se carga localmente, sin depender de una CDN al jugar.
- La configuración de orientación y pantalla completa se aplica de forma repetible, sin duplicar atributos ni estilos.
- Este repositorio no contiene todavía un APK compilado ni una prueba en un dispositivo físico. La compilación requiere Android Studio y el SDK en el equipo donde se ejecute el script.

Para generar un AAB de publicación, abre `app/android/` en Android Studio y configura la firma de lanzamiento antes de crear el paquete.
