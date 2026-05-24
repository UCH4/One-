# 📋 Guía de Migración: UIKit → SwiftUI (para Skip)

## Qué hace cada archivo nuevo

| Archivo nuevo | Reemplaza (UIKit) | Por qué cambió |
|---|---|---|
| `OneApp.swift` | `AppDelegate.swift` + `SceneDelegate.swift` | Skip no puede traducir UIKit lifecycle |
| `RootView.swift` | Lógica de AppDelegate que revisaba si había sesión | Centraliza la navegación raíz |
| `AuthViewModel.swift` | Código Firebase en `LoginViewController` y `RecordViewController` | Skip necesita ObservableObject, no IBActions |
| `LoginView.swift` | `LoginViewController` + storyboard scene | SwiftUI = compatible iOS y Android |
| `HomeView.swift` | `HomeViewController` + storyboard scene | Reemplaza IBOutlets y segues |
| `ShareView.swift` | `ShareViewController` + storyboard scene | Reemplaza UIPickerView y UIDatePicker |
| `PartidosView.swift` | `PartidosTableViewController` + storyboard | Reemplaza UITableView + UISwitch |
| `MapasView.swift` | `MapasViewController` + MKMapView UIKit | Map{} SwiftUI → Google Maps Android vía Skip |
| `RegisterView.swift` | `RecordViewController` + storyboard | Reemplaza UIPickerView de posiciones |
| `PerfilClienteView.swift` | `PerfilClienteViewController` + storyboard | Reemplaza todos los UITextField |
| `PartidoViewModel.swift` | Código Firestore en HomeViewController | Observable para SwiftUI + Skip |
| `Package.swift` | `Podfile` + `Podfile.lock` | Skip usa SPM, no CocoaPods |

---

## Archivos que HAY QUE ELIMINAR del módulo App de Skip

Estos son los que causan tus errores de compilación actuales:

```
❌ AppDelegate.swift
❌ SceneDelegate.swift
❌ LoginViewController.swift
❌ HomeViewController.swift
❌ ShareViewController.swift
❌ PartidosTableViewController.swift
❌ MapasViewController.swift
❌ RecordViewController.swift
❌ PerfilClienteViewController.swift
❌ Main.storyboard
❌ Pods/ (carpeta completa)
❌ Podfile
❌ Podfile.lock
```

**No elimines:**
```
✅ Models/         (código Swift puro sin UIKit)
✅ GoogleService-Info.plist
✅ Assets.xcassets
✅ Info.plist
```

---

## Equivalencias exactas Storyboard → SwiftUI

### Navegación
```
segue kind="presentation"  →  .navigationDestination(isPresented: $show)
segue kind="show"          →  NavigationLink o .navigationDestination
segue kind="relationship"  →  NavigationStack { RootView() }
```

### Controles
```
UITextField          →  TextField / SecureField
UIPickerView         →  Picker(.wheel)
UIDatePicker         →  DatePicker(.compact / .graphical)
UITableView          →  List
UITableViewCell      →  struct RowView: View
UISwitch             →  Toggle
MKMapView (UIKit)    →  Map (SwiftUI/MapKit) ← Skip lo traduce a Google Maps
UIActivityIndicator  →  ProgressView()
UIButton             →  Button { } label: { }
```

### Ciclo de vida
```
viewDidLoad()        →  .onAppear { }
viewWillDisappear()  →  .onDisappear { }
IBAction             →  closure en Button { } o .onChange
IBOutlet             →  @State / @Published
```

---

## Pasos de instalación en tu proyecto Skip

```bash
# 1. Eliminar CocoaPods
rm -rf Pods Podfile Podfile.lock

# 2. Si no tenés Skip CLI todavía
brew install skiptools/skip/skip

# 3. Crear estructura Skip (si partís de cero)
skip init --appid=com.tuempresa.one One

# 4. Copiar los archivos Swift a la carpeta Sources/One/
cp *.swift /ruta/a/tu/proyecto/Sources/One/

# 5. Correr en simulador iOS
skip run ios

# 6. Correr en Android
skip run android
```

---

## Errores comunes que vas a ver (y cómo resolverlos)

| Error | Causa | Solución |
|---|---|---|
| `cannot find type 'UIViewController'` | Archivo UIKit todavía en el target | Eliminar ese archivo del módulo App |
| `unable to open base configuration...Pods` | Podfile roto | Borrar Pods/, correr `skip init` de nuevo |
| `Module 'SwiftKeychainWrapper' not found` | Era un pod de CocoaPods | Reemplazar con `Keychain` nativo o `UserDefaults` |
| `No such module 'FirebaseCore'` | No agregaste el package SPM | Agregar la URL de firebase-ios-sdk en Package.swift |
