# One

![ponele que un logo](https://placehold.co/400x150/007AFF/FFFFFF?text=Uno Mas)

Aplicación móvil diseñada para la organización, gestión y búsqueda de partidos de fútbol amateur en tiempo real. Permite a los usuarios crear partidos en ubicaciones específicas y gestionar solicitudes de otros jugadores que deseen unirse para cubrir las posiciones faltantes.

##  Tecnologías Utilizadas

| Categoría | Tecnología | Uso |
| :--- | :--- | :--- |
| **Frontend (Actual)** | Swift (UIKit) | Desarrollo nativo para iOS. |
| **Backend** | Firebase Firestore | Base de datos NoSQL para datos de partidos, jugadores y solicitudes en tiempo real. |
| **Autenticación** | Firebase Authentication | Gestión de sesiones de usuario (registro, inicio de sesión). |
| **Almacenamiento** | SwiftKeychainWrapper | Almacenamiento seguro de credenciales de usuario. |

##  Características Principales

* **Autenticación de Jugadores:** Registro y login de usuarios a través de Firebase Auth.
* **Creación de Partidos:** Los usuarios pueden establecer la dirección, fecha, hora y posición solicitada para un nuevo partido.
* **Gestión de Solicitudes:**
    * **Jugador Solicitante (Creador):** Ve y administra las solicitudes para su partido.
    * **Jugador Solicitado (Unido):** Ve el estado de su participación (pendiente, aceptada, rechazada).
* **Actualizaciones en Tiempo Real:** Uso de *listeners* de Firestore para reflejar el estado de los partidos inmediatamente en la interfaz.
* **Indicadores Visuales:** Celdas de tabla con códigos de color para identificar rápidamente el estado de confirmación de un partido (Verde, Amarillo, Rojo).

##  Instalación y Configuración

Para ejecutar este proyecto localmente, sigue estos pasos:

1.  **Clonar el Repositorio:**
    ```bash
    git clone [https://github.com/UCH4/One.git](https://github.com/UCH4/One.git)
    cd One
    ```

2.  **Configurar Firebase:**
    * Crea un nuevo proyecto en la [Consola de Firebase](https://console.firebase.google.com/).
    * Añade una aplicación iOS a tu proyecto.
    * Descarga el archivo `GoogleService-Info.plist` y colócalo en el directorio raíz del proyecto Xcode.

3.  **Dependencias (CocoaPods):**
    * Asegúrate de tener CocoaPods instalado.
    * Instala las dependencias:
        ```bash
        pod install
        ```
    * Abre el proyecto usando el archivo `.xcworkspace`.

4.  **Ejecutar:**
    * Selecciona un simulador o dispositivo iOS y ejecuta el proyecto desde Xcode.

## Futuras Mejoras (Roadmap)

Este proyecto está en continua evolución. Las siguientes funcionalidades representan los pasos clave para escalar y modernizar la aplicación:

### 1. **Geolocalización y Mapas** 🗺️
* Integración con **Google Maps SDK for iOS**.
* **Selección de Cancha por Mapa:** Permitir al usuario seleccionar la ubicación del partido arrastrando un pin o usando la búsqueda de direcciones (Places SDK).
* **Búsqueda Visual:** Mostrar los partidos disponibles mediante pines en un mapa interactivo.

### 2. **Optimización de Backend (Cloud Functions)** ☁️
* Implementar **Cloud Functions** para manejar la lógica crítica del negocio (ej. Aceptar Solicitud).
* Usar *Triggers* de Firestore para actualizar documentos de forma atómica y segura, eliminando la dependencia de complejas anidaciones en el cliente.
* Implementar notificaciones push a través de Firebase Cloud Messaging (FCM) para alertar a los jugadores sobre solicitudes aceptadas.

### 3. **Escalado Multiplataforma** 🔄
* Migrar el código base a un *framework* multiplataforma (como **React Native** o **Flutter**) para soportar iOS y Android desde un código único.
* Utilizar **JavaScript/TypeScript** para la lógica de la aplicación y aprovechar las herramientas modernas de desarrollo web/móvil.
