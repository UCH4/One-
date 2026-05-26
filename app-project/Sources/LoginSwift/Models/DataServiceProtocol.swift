import Foundation

// Definición de un error genérico
enum DataServiceError: Error {
    case dataNotFound
    case authenticationError
    case internalError(String)
}

protocol DataService {
    // JUGADORES
    func fetchJugadores(uid: String, completion: @escaping (Result<Jugadores, DataServiceError>) -> Void)
    
    // PARTIDOS
    func fetchPartidos(completion: @escaping (Result<[Partidos], DataServiceError>) -> Void)
    func createPartido(partido: Partidos, completion: @escaping (Result<String, DataServiceError>) -> Void) // Devuelve ID
    
    // SOLICITUDES
    func fetchSolicitudes(for jugadorID: String, completion: @escaping (Result<[Solicitudes], DataServiceError>) -> Void)
    func updateSolicitudStatus(id: String, esSolicitante: Bool, acepta: Bool, completion: @escaping (Result<Void, DataServiceError>) -> Void)
}
