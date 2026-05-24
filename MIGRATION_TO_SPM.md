# Migración de CocoaPods a Swift Package Manager (SPM) para LoginSwift

Este documento te guía para: (1) reparar el proyecto tras iCloud, (2) eliminar CocoaPods, (3) integrar Firebase, Google Maps/Places y SwiftKeychainWrapper con SPM, y (4) ajustar el código de arranque.

---

## 1) Reparar archivos y permisos tras iCloud

1. Mueve la carpeta del proyecto fuera de iCloud Drive (por ejemplo a `~/Developer/LoginSwift`).
2. En Finder, asegúrate de que todos los archivos estén descargados localmente (sin icono de nube). Si ves el icono de nube, usa “Descargar ahora”.
3. Verifica permisos de lectura/escritura para tu usuario en toda la carpeta del proyecto (Archivo > Obtener información).
4. Si el error de `actool` persiste por `Assets.xcassets/Contents.json`:
   - Cierra Xcode.
   - Renombra `LoginSwift/Assets.xcassets` a `Assets_backup.xcassets`.
   - Abre Xcode, crea un nuevo Asset Catalog (File > New > File > Asset Catalog) llamado `Assets.xcassets` y vuelve a agregar tus imágenes.
5. Limpia la carpeta de derivados: en Xcode, Product > Clean Build Folder (mantén Option para ver la opción avanzada) y borra `~/Library/Developer/Xcode/DerivedData/*` si es necesario.

Esto resuelve el error:
- `failed to read asset tags ... The file “Contents.json” couldn’t be opened because you don’t have permission ...`

---

## 2) Eliminar CocoaPods completamente

1. Cierra Xcode.
2. En la raíz del proyecto, ejecuta:
