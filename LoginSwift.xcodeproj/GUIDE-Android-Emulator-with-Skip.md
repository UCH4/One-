// Ejecutar también en emulador de Android desde Xcode usando skip

Esta guía te ayuda a configurar el entorno Android, instalar skip y añadir un Run Script en Xcode para lanzar el emulador y ejecutar tu proyecto Android en paralelo al correr tu app iOS.

## 1) Preparar entorno Android en macOS

- Instala Android Studio (recomendado) para tener SDK Manager y AVD Manager.
- La ruta por defecto del SDK en macOS suele ser: `~/Library/Android/sdk`.
- Configura variables de entorno en tu `~/.zshrc`:
  ```bash
  echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
  source ~/.zshrc
