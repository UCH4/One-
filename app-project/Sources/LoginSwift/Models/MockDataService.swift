import Foundation

class MockDataService: DataService {
    
    // DATOS HARDCODEADOS (La "Base Provisional")
    private var mockJugadores: [Jugador] = [
      
    ]
    
    private var mockPartidos: [Partido] = [
        
    ]
    
    private var mockSolicitudes: [Solicitud] = [
      
    ]
    
    private let delay: TimeInterval = 1.0 // Simula la latencia de red

    // Helper para simular latencia
    private func simulateNetwork(callback: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: callback)
    }

    // MARK: - JUGADORES
    func fetchJugador(uid: String, completion: @escaping (Result<Jugador, DataServiceError>) -> Void) {
        simulateNetwork {
            if let jugador = self.mockJugadores.first(where: { $0.uid == uid }) {
                completion(.success(jugador))
            } else {
                completion(.failure(.dataNotFound))
            }
        }
    }

    // MARK: - PARTIDOS
    func fetchPartidos(completion: @escaping (Result<[Partidos], DataServiceError>) -> Void) {
        simulateNetwork {
            completion(.success(self.mockPartidos))
        }
    }
    
    func createPartido(partido: Partidos, completion: @escaping (Result<String, DataServiceError>) -> Void) {
        simulateNetwork {
            // Asigna un ID temporal para el Mock
            var newPartido = partido
            let newID = UUID().uuidString
            newPartido = Partidos(id: newID, idJugadorSolicitante: partido.idJugadorSolicitante, idJugadorSolicitado: partido.idJugadorSolicitado, direccion: partido.direccion, dia: partido.dia, posicion: partido.posicion, confirmacion2: partido.confirmacion2)

            self.mockPartidos.append(newPartido)
            print("MOCK: Partido creado con ID: \(newID)")
            completion(.success(newID))
        }
    }

    // MARK: - SOLICITUDES
    func fetchSolicitudes(for jugadorID: String, completion: @escaping (Result<[Solicitud], DataServiceError>) -> Void) {
        simulateNetwork {
            let filteredSolicitudes = self.mockSolicitudes.filter { $0.idJugadorSolicitante == jugadorID || $0.idJugadorSolicitado == jugadorID }
            completion(.success(filteredSolicitudes))
        }
    }
    
    func updateSolicitudStatus(id: String, esSolicitante: Bool, acepta: Bool, completion: @escaping (Result<Void, DataServiceError>) -> Void) {
        simulateNetwork {
            if let index = self.mockSolicitudes.firstIndex(where: { $0.idSolicitud == id }) {
                if esSolicitante {
                    self.mockSolicitudes[index].aceptarSolicitante = acepta
                } else {
                    self.mockSolicitudes[index].aceptarSolicitado = acepta
                }
                print("MOCK: Solicitud \(id) actualizada.")
                completion(.success(()))
            } else {
                completion(.failure(.dataNotFound))
            }
        }
    }
}
