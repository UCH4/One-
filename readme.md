# One-

**Aplicación iOS para encontrar un jugador faltante en partidos de fútbol amateur**

---

## Resumen

One- es una aplicación iOS escrita en Swift que facilita la publicación y la búsqueda de jugadores para completar partidos de fútbol comunitarios. Utiliza Firebase (Authentication y Firestore) como backend, SwiftKeychainWrapper para persistencia segura del `uid` y CocoaPods para dependencias.

Este documento resume la intención de la app, describe el flujo funcional, analiza el código fuente principal subido (LoginViewController, HomeViewController, PartidosTableViewController), enumera falencias detectadas y propone mejoras técnicas y funcionales estructuradas desde la perspectiva de un desarrollador senior.

---

## Objetivo funcional

Permitir a un usuario crear una publicación anunciando que falta un jugador para un partido y, a su vez, permitir que otros usuarios se inscriban para cubrir esa posición. La aplicación debe gestionar autenticación, listado de partidos, solicitudes de unión y la confirmación mutua entre creador y jugador.

---

## Arquitectura (actual)

- Lenguaje: Swift
- UI: UIKit (storyboards / view controllers)
- Backend: Firebase Authentication (Auth), Firestore (DB)
- Persistencia local mínima: Keychain via SwiftKeychainWrapper (guarda `userUID`) y UserDefaults (en algunos controladores)
- Dependencias: CocoaPods (Pods/)
- Patrón: mezcla de responsabilidades; se observa una aproximación parcial a MVVM/Service pero con lógica de negocio y acceso a Firestore directamente desde los view controllers.

---

## Colecciones y modelos en Firestore (observados en el código)

- `Jugadores` — documentos por usuario con al menos: `posicion_preferente`, `email`, otros datos de perfil.
- `Partidos` — documentos por partido con campos: `direccion`, `dia` (Timestamp), `posicion`, `id_jugador_solicitante`, `id_jugador_solicitado`, `confirmacion_2`.
- `Solicitudes` — documentos que representan la intención de un jugador de unirse a un partido: `id_solicitud`, `id_jugador_solicitante`, `id_jugador_solicitado`, `id_partido`, `aceptar_solicitado`, `aceptar_solicitante`, `updatedAt` (en algunas operaciones).

---

## Flujo del usuario (alto nivel)

1. **Login**: el usuario inicia sesión con email/password mediante Firebase Auth (`LoginViewController`). Al autenticarse se presenta `HomeViewController`.
2. **Home**: `HomeViewController` crea listeners en Firestore para dos conjuntos de datos: partidos creados por el usuario y solicitudes relacionadas (tanto si el usuario solicitó como si fue solicitado). Los datos se combinan en memoria (`partidosMap`, `solicitudesMapPorPartido`) y se muestran en dos tablas: *Partidos creados* y *Partidos unidos*.
3. **Listado público**: `PartidosTableViewController` escucha la colección `Partidos` y filtra partidas que ya tengan `id_jugador_solicitado` vacío y `dia` posterior a la fecha actual. Además ofrece un switch para mostrar solo partidos cuya `posicion` coincida con la `posicion_preferente` del usuario.
4. **Unirse**: cuando un usuario se une, `PartidosTableViewController` crea un documento en `Solicitudes`. El flujo intenta (parcialmente) actualizar el partido con el `id_jugador_solicitado` cuando la solicitud es aceptada por ambas partes (lógica principalmente en `PartidosTableViewController` / `HomeViewController`).
5. **Confirmación**: `HomeViewController` escucha cambios en `Solicitudes`. Si detecta que tanto `aceptar_solicitante` como `aceptar_solicitado` están en `"true"`, actualiza el documento del partido con `confirmacion_2: "true"` y fija `id_jugador_solicitado`.

---

## Análisis de los archivos principales

### LoginViewController.swift
- **Responsabilidad principal**: autenticación por email/contraseña y envío de correo de restablecimiento.
- **Observaciones técnicas**:
  - Correcto uso de `Auth.auth().signIn` con manejo de errores y navegación a `HomeViewController` en caso de éxito.
  - UI: layout manual para placeholders y botón con gradiente; `UITextFieldDelegate` implementado.
  - `forgotPasswordButtonPressed` valida formato y comprueba existencia en `Jugadores` antes de invocar `sendPasswordReset`. Esta verificación puede ser redundante (Firebase puede enviar el reset incluso si no existe) pero aumenta el buen feedback al usuario.
- **Oportunidades de mejora**:
  - Extraer validaciones y presentación de alertas a utilitarios/servicios para reducir código en el controlador.
  - Evitar lógica de navegación acoplada al controlador directamente; inyectar coordinador o usar un router.
  - Considerar manejo de estados de UI (loading, error) mediante un ViewModel para facilitar testing.

### HomeViewController.swift
- **Responsabilidad principal**: mostrar partidas creadas por el usuario y partidas donde el usuario está unido; sincronizar `Partidos` y `Solicitudes`.
- **Observaciones técnicas**:
  - Uso de `ListenerRegistration` para suscripciones en Firestore; buena práctica remover listeners en `viewWillDisappear`.
  - Mantiene dos listeners separados: uno para `Partidos` creados por el usuario y otro para `Solicitudes` relevantes. Sincroniza datos en `partidosMap` y `solicitudesMapPorPartido`.
  - Método `sincronizarDatos()` combina y produce dos arrays para las tablas — aproximación correcta para separar datos escuchados y UI.
- **Oportunidades de mejora**:
  - Extracción de lógica de Firestore a un servicio `FirestoreService` con métodos `listenPartidosByUser(uid:)`, `listenSolicitudesForUser(uid:)`, `getPartidos(byIds:)`.
  - Manejo más estricta de errores y estados (vacío, cargando, error) con notificaciones a la UI.
  - Evitar accesos repetidos a `KeychainWrapper.standard` cada vez que se pide `id_jugador`; en su lugar, resolver en inicialización del componente o inyectar el UID.
  - Los comparadores y ordenamientos (p. ej. orden por fecha o por id) deben ser explícitos y consistentes.

### PartidosTableViewController.swift
- **Responsabilidad principal**: listar partidos disponibles y permitir unirse.
- **Observaciones técnicas**:
  - `fetchPartidos()` escucha toda la colección `Partidos` y filtra localmente los partidos con `id_jugador_solicitado` vacío y fecha futura. También borra automáticamente partidos caducados (`db.collection("Partidos").document(doc.documentID).delete()`), lo cual es una simplificación válida pero debe usarse con cuidado — borrar datos automágicamente puede provocar pérdida si la fecha fue mal guardada.
  - Al crear una solicitud (`unirseAlPartido`) se comprueba si ya existe una solicitud previa para el mismo par (partido, usuario). Es una buena práctica.
  - Hay código comentado que antes actualizaba el partido directamente; ahora la confirmación se hace mediante la tabla de solicitudes y la lógica de aceptación.
- **Oportunidades de mejora**:
  - Evitar borrar automáticamente documentos del servidor desde el cliente; en su lugar, marcar como `estado: "expirado"` y un job server-side o función Cloud Function puede limpiarlos.
  - Cuando se crea la `Solicitud`, debería evitarse condiciones de carrera: usar transacciones o `document().setData(..., merge: false)` con validaciones servidor-side para impedir doble reserva.
  - Mejorar UX: bloquear el botón mientras se crea la solicitud y ofrecer retroalimentación clara.

---

## Falencias detectadas (resumen)

1. **Mezcla de responsabilidades**: acceso directo a Firestore desde view controllers. Dificulta testing y escalado.
2. **Validaciones inconsistentes**: no todas las entradas están validadas exhaustivamente (dirección libre, fecha, posición).
3. **Manejo de concurrencia**: creación y confirmación de solicitudes pueden sufrir condiciones de carrera si dos usuarios intentan unirse simultáneamente.
4. **Borrado directo desde cliente**: eliminar partidos caducados desde el cliente es frágil.
5. **Escasa normalización de datos**: posiciones como strings; sería mejor tener enums/constantes o una colección `Posiciones`.
6. **Falta de pruebas y coverage**: no hay evidencia de tests unitarios ni mocks para Firestore.
7. **UI feedback y estados**: falta manejo estandarizado de estados (loading, success, error) en varias operaciones.

---

## Seguridad y secretos

- El proyecto incluye `GoogleService-Info.plist` para Firebase. Ese archivo identifica el proyecto Firebase — no es un secreto absoluto, pero no debe contener credenciales privadas del backend.
- Evitar subir certificados privados (`.p12`), claves de API sensibles o archivos `.env` con secretos al repositorio público.
- Recomendación: utilizar `plist` de configuración por entorno (dev/staging/prod) y no commitear archivos de producción.

---

## Recomendaciones técnicas (priorizadas)

1. **Refactor: extraer capa de acceso a datos**
   - Crear `FirestoreService` y `AuthService` responsables de las queries y listeners.
   - Interfaces/protocolos para permitir mocking en tests.
2. **Aplicar patrón MVVM**
   - ViewModels por pantalla que expongan estados e inputs. Reducir la lógica en los view controllers.
3. **Transacciones y reglas Firestore**
   - Mover la lógica crítica de confirmación a Cloud Functions o utilizar transacciones para evitar race conditions.
   - Definir reglas de seguridad en Firestore para asegurar que solo usuarios legítimos puedan escribir ciertos campos.
4. **Normalizar posiciones**
   - Pasar de strings arbitrarios a enums y/o colección documental para facilitar traducción y búsquedas.
5. **Limpieza de datos**
   - Reemplazar borrados automáticos por marcadores (`status: expired`) y un job server-side (Cloud Functions) que archive o elimine.
6. **Mejorar UX y validaciones**
   - Validar dirección con Autocomplete (MapKit / Google Places).
   - Validaciones de fecha y horario (no permitir fechas en el pasado al crear partido).
7. **Logs y manejo de errores**
   - Centralizar reporting de errores (Sentry / Crashlytics) y agregar más logs estructurados.
8. **Tests**
   - Unit tests para ViewModels y servicios; tests de integración para reglas de Firestore.

---

## Roadmap y features sugeridas (funcional y técnico)

### Prioridad Alta
- Integración de mapas (MapKit/Google Maps) con autocompletado y geocodificación.
- Sistema de confirmaciones seguro mediante transacciones o Cloud Functions.
- Validaciones exhaustivas en creación de partido.

### Prioridad Media
- Sistema de reputación y valoraciones (dual rating system).
- Matchmaking por proximidad / disponibilidad.
- Notificaciones push para solicitudes y confirmaciones (FCM).

### Prioridad Baja
- Clasificatorios y sistema de niveles.
- Chat interno por partido.
- Historial detallado de partidos jugados y estadísticas.

---

## Instrucciones para desarrolladores (setup)

1. Clonar el repositorio
```bash
git clone https://github.com/UCH4/One-.git
cd One-
```

2. Instalar dependencias (CocoaPods)
```bash
pod install
open One-.xcworkspace
```

3. Firebase
- Añadir `GoogleService-Info.plist` en el workspace (no commits de producción a GitHub).
- Configurar Authentication y Firestore en la consola de Firebase.

4. Ejecutar en dispositivo o simulador.

---

## Siguientes pasos sugeridos por el equipo senior

1. Implementar `FirestoreService` y `AuthService` con protocolos.
2. Refactor completo de `HomeViewController` a MVVM.
3. Migrar borrado automático a Cloud Function y crear pruebas unitarias para la lógica de confirmación.
4. Implementar MapKit/Google Places para la dirección de la cancha.

---

## Contribuciones

Las pull requests son bienvenidas. Para cambios grandes, abrir una issue describiendo objetivo, diseño y plan de pruebas.

---

## Licencia

Especificar la licencia del proyecto (ej. MIT) según prefieras.

---

Si querés que incluya diagramas de flujo o un árbol de archivos con ejemplos de refactor (por ejemplo, código de `FirestoreService` y de un `PartidosViewModel`) lo genero y lo subo en archivos separados listos para descargar.

