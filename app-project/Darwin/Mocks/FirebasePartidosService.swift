//
//  FirebasePartidosService.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 12/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirebasePartidosService: PartidosDataService {
    private let db = Firestore.firestore()
    private var cacheSolicitudesPorPartido: [String: (timestamp: Date, data: [Solicitud])] = [:]
    private var cachePartidosDisponibles: (filtroKey: String, timestamp: Date, data: [Partido])?

    private let ttl: TimeInterval = 30 // 30s de frescura; ajustable

    func obtenerSolicitudes(partidoId: String) async throws -> [Solicitud] {
        if let c = cacheSolicitudesPorPartido[partidoId],
           Date().timeIntervalSince(c.timestamp) < ttl {
            return c.data
        }
        // Llamado a Firestore (async) solo si cache venció o no existe
        let snapshot = try await db.collection("Solicitudes").whereField("id_partido", isEqualTo: partidoId).getDocumentsAsync()
        let items: [Solicitud] = snapshot.documents.map { doc in
            let d = doc.data()
            return Solicitud(
                id_solicitud: doc.documentID,
                id_jugador_solicitante: d["id_jugador_solicitante"] as? String ?? "",
                id_jugador_solicitado: d["id_jugador_solicitado"] as? String ?? "",
                id_partido: d["id_partido"] as? String,
                aceptar_solicitado: d["aceptar_solicitado"] as? String,
                aceptar_solicitante: d["aceptar_solicitante"] as? String,
                jugadorInfo: nil
            )
        }
        cacheSolicitudesPorPartido[partidoId] = (Date(), items)
        return items
    }

    func actualizarEstadoSolicitud(id: String, aceptarSolicitante: String?, aceptarSolicitado: String?) async throws {
        var fields: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
        if let a = aceptarSolicitante { fields["aceptar_solicitante"] = a }
        if let b = aceptarSolicitado { fields["aceptar_solicitado"] = b }

        try await db.collection("Solicitudes").document(id).updateDataAsync(fields)

        // Invalidar cache del partido al que pertenece esa solicitud (si lo conoces)
        // Alternativa: invalidar todo el cache de solicitudes
        cacheSolicitudesPorPartido.removeAll()
    }

    func obtenerPartidosDisponibles(filtro: FiltroPartidos) async throws -> [Partido] {
        let key = "\(filtro.soloCoincidentesConPosicion ?? "nil")_\(filtro.soloDisponibles)"
        if let c = cachePartidosDisponibles, c.filtroKey == key, Date().timeIntervalSince(c.timestamp) < ttl {
            return c.data
        }
        // Construye query según filtro...
        let snapshot = try await db.collection("Partidos").getDocumentsAsync()
        var items: [Partido] = snapshot.documents.compactMap { doc in
            let d = doc.data()
            guard let direccion = d["direccion"] as? String,
                  let ts = d["dia"] as? Timestamp,
                  let posicion = d["posicion"] as? String,
                  let solicitante = d["id_jugador_solicitante"] as? String,
                  let solicitado = d["id_jugador_solicitado"] as? String
            else { return nil }

            let confirmacion2 = d["confirmacion_2"] as? String ?? ""
            let partido = Partido(
                id: doc.documentID,
                direccion: direccion,
                dia: ts.dateValue(),
                posicion: posicion,
                id_jugador_solicitante: solicitante,
                id_jugador_solicitado: solicitado,
                confirmacion_2: confirmacion2
            )
            return partido
        }
        // Aplica filtro en memoria si hace falta
        if let pos = filtro.soloCoincidentesConPosicion {
            items = items.filter { $0.posicion == pos }
        }
        if filtro.soloDisponibles {
            items = items.filter { $0.id_jugador_solicitado.isEmpty }
        }

        cachePartidosDisponibles = (key, Date(), items)
        return items
    }

    func crearPartido(_ partido: Partido) async throws {
        try await db.collection("Partidos").document(partido.id).setDataAsync([
            "direccion": partido.direccion,
            "dia": Timestamp(date: partido.dia),
            "posicion": partido.posicion,
            "id_jugador_solicitante": partido.id_jugador_solicitante,
            "id_jugador_solicitado": partido.id_jugador_solicitado,
            "confirmacion_2": partido.confirmacion_2
        ])
        // invalidar cache de partidos
        cachePartidosDisponibles = nil
    }

    func unirseAPartido(_ partido: Partido, uidSolicitado: String) async throws {
        let ref = db.collection("Solicitudes").document()
        try await ref.setDataAsync([
            "id_solicitud": ref.documentID,
            "id_jugador_solicitado": uidSolicitado,
            "id_jugador_solicitante": partido.id_jugador_solicitante,
            "id_partido": partido.id,
            "aceptar_solicitado": "pendiente",
            "aceptar_solicitante": "pendiente"
        ])
        // invalidar cache de solicitudes de ese partido
        cacheSolicitudesPorPartido.removeValue(forKey: partido.id)
    }

    func obtenerDatosDeUsuario(uid: String) async throws -> Jugador {
        let doc = try await db.collection("Jugadores").document(uid).getDocumentAsync()
        let d = doc.data() ?? [:]
        return Jugador(
            id: uid,
            nombre: d["nombre"] as? String ?? "",
            mail: d["email"] as? String ?? "",
            posicion: d["posicion_preferente"] as? String ?? "",
            apellido: d["apellido"] as? String ?? ""
        )
    }
}
import FirebaseFirestore

extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            self.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: -1))
                }
            }
        }
    }
}

extension DocumentReference {
    func setDataAsync(_ data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func updateDataAsync(_ fields: [AnyHashable: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.updateData(fields) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func getDocumentAsync() async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            self.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: -1))
                }
            }
        }
    }
}
