import SkipFirebaseCore
import SkipFirebaseAuth
import SkipFirebaseFirestore

struct Jugador: Equatable, Hashable {
    var id: String
    var nombre: String
    var mail: String
    var posicion: String
    var apellido: String
}

struct Solicitud: Equatable, Hashable {
    var id_solicitud: String
    var id_jugador_solicitante: String
    var id_jugador_solicitado: String
    var id_partido: String?
    var aceptar_solicitado: String?
    var aceptar_solicitante: String?
    var jugadorInfo: Jugador?
}

struct Partido: Equatable, Hashable {
    var id: String
    var direccion: String
    var dia: Date
    var posicion: String
    var id_jugador_solicitante: String
    var id_jugador_solicitado: String
    var confirmacion_2: String
}

struct PartidoConSolicitud: Equatable, Hashable {
    var partido: Partido
    var solicitud: Solicitud?
}
