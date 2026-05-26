import Foundation

// MARK: - JUGADOR

struct Jugadores {
    let uid: String
    let nombre: String
    let apellido: String
    let email: String
    let posicionPreferente: String

    // Inicializador a partir de datos (útil para Firestore real o Mock)
    init(uid: String, nombre: String, apellido: String, email: String, posicionPreferente: String) {
        self.uid = uid
        self.nombre = nombre
        self.apellido = apellido
        self.email = email
        self.posicionPreferente = posicionPreferente
    }
}

// MARK: - PARTIDO

struct Partidos {
    let id: String
    let idJugadorSolicitante: String
    let idJugadorSolicitado: String
    let direccion: String
    let dia: Date // Usamos Date en Swift en lugar de Timestamp
    let posicion: String
    var confirmacion2: String // 'pendiente', 'aceptada', 'rechazada'

    // Datos que simulan la estructura de Firestore
    init(id: String, idJugadorSolicitante: String, idJugadorSolicitado: String, direccion: String, dia: Date, posicion: String, confirmacion2: String) {
        self.id = id
        self.idJugadorSolicitante = idJugadorSolicitante
        self.idJugadorSolicitado = idJugadorSolicitado
        self.direccion = direccion
        self.dia = dia
        self.posicion = posicion
        self.confirmacion2 = confirmacion2
    }
}

// MARK: - SOLICITUD

struct Solicitudes {
    let idSolicitud: String
    let idPartido: String
    let idJugadorSolicitante: String
    let idJugadorSolicitado: String
    var aceptarSolicitante: Bool // true/false
    var aceptarSolicitado: Bool  // true/false
    let updatedAt: Date

    init(idSolicitud: String, idPartido: String, idJugadorSolicitante: String, idJugadorSolicitado: String, aceptarSolicitante: Bool, aceptarSolicitado: Bool, updatedAt: Date) {
        self.idSolicitud = idSolicitud
        self.idPartido = idPartido
        self.idJugadorSolicitante = idJugadorSolicitante
        self.idJugadorSolicitado = idJugadorSolicitado
        self.aceptarSolicitante = aceptarSolicitante
        self.aceptarSolicitado = aceptarSolicitado
        self.updatedAt = updatedAt
    }
}
