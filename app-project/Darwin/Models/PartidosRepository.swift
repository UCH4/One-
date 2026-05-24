//
//  PartidosRepository.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 12/12/2025.
//

import Foundation
import SkipFirebase

import FirebaseFirestore
import FirebaseAuth

class PartidosRepository {
    
    // SINGLETON: Una única instancia compartida para toda la app
    static let shared = PartidosRepository()
    
    // DATOS EN MEMORIA (Tu "Base local")
    // El Home leerá directamente de aquí
    var partidosCreados: [PartidoConSolicitud] = []
    var partidosUnidos: [PartidoConSolicitud] = []
    
    // Callback: Para avisarle al Home cuando lleguen cambios
    var didUpdateData: (() -> Void)?
    
    // Variables privadas de Firebase
    private let db = Firestore.firestore()
    private var listenerPartidos: ListenerRegistration?
    private var listenerSolicitudes: ListenerRegistration?
    
    // Mapas para procesar datos rápido
    private var partidosMap: [String: Partido] = [:]
    private var solicitudesMap: [String: [Solicitud]] = [:]
    
    private init() {} // Privado para que nadie cree otra instancia
    
    // Función para iniciar la escucha (se llama 1 sola vez)
    func escucharDatos() {
        // Si ya estamos escuchando, no hacemos nada (evita duplicados)
        if listenerPartidos != nil { return }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        print("🎧 REPO: Iniciando escucha en Firestore...")
        
        // 1. ESCUCHAR MIS PARTIDOS (CREADOS)
        listenerPartidos = db.collection("Partidos")
            .whereField("id_jugador_solicitante", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error { print("Error Partidos: \(error)"); return }
                
                snapshot?.documentChanges.forEach { change in
                    let p = self.crearPartido(doc: change.document)
                    if change.type == .removed {
                        self.partidosMap.removeValue(forKey: p.id)
                    } else {
                        self.partidosMap[p.id] = p
                    }
                }
                self.procesarListas(uid: uid)
            }
            
        // 2. ESCUCHAR MIS SOLICITUDES (UNIDOS)
        listenerSolicitudes = db.collection("Solicitudes")
            .whereFilter(Filter.orFilter([
                Filter.whereField("id_jugador_solicitante", isEqualTo: uid),
                Filter.whereField("id_jugador_solicitado", isEqualTo: uid)
            ]))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error { print("Error Solicitudes: \(error)"); return }
                
                // Reconstruimos el mapa de solicitudes
                var tempMap: [String: [Solicitud]] = [:]
                snapshot?.documents.forEach { doc in
                    let s = self.crearSolicitud(doc: doc)
                    if let pid = s.id_partido {
                        tempMap[pid, default: []].append(s)
                    }
                }
                self.solicitudesMap = tempMap
                
                // Si hay solicitudes de partidos que no tenemos en el mapa (porque no los creé yo), los buscamos
                let idsPartidosNecesarios = Array(tempMap.keys)
                self.descargarPartidosFaltantes(ids: idsPartidosNecesarios, uid: uid)
            }
    }
    
    // Descarga partidos ajenos una sola vez si no los tengo en memoria
    private func descargarPartidosFaltantes(ids: [String], uid: String) {
        let faltantes = ids.filter { partidosMap[$0] == nil }
        
        if !faltantes.isEmpty {
            // Dividimos en grupos de 10 porque Firebase no deja buscar más de 10 IDs a la vez
            let chunk = Array(faltantes.prefix(10))
            db.collection("Partidos").whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, _ in
                    snapshot?.documents.forEach { doc in
                        let p = self.crearPartido(doc: doc)
                        self.partidosMap[p.id] = p
                    }
                    self.procesarListas(uid: uid)
                }
        } else {
            self.procesarListas(uid: uid)
        }
    }
    
    // Cruza la información y avisa al Home
    private func procesarListas(uid: String) {
        var creados: [PartidoConSolicitud] = []
        var unidos: [PartidoConSolicitud] = []
        
        for (_, partido) in partidosMap {
            let solicitudesDelPartido = solicitudesMap[partido.id] ?? []
            
            if partido.id_jugador_solicitante == uid {
                // Es un partido MÍO
                let ultimaSol = solicitudesDelPartido.sorted { $0.id_solicitud > $1.id_solicitud }.first
                creados.append(PartidoConSolicitud(partido: partido, solicitud: ultimaSol))
            } else if let miSolicitud = solicitudesDelPartido.first(where: { $0.id_jugador_solicitado == uid }) {
                // Es un partido al que me UNÍ
                unidos.append(PartidoConSolicitud(partido: partido, solicitud: miSolicitud))
            }
        }
        
        // Actualizamos las variables públicas
        self.partidosCreados = creados
        self.partidosUnidos = unidos
        
        print("✅ REPO: Datos actualizados. Creados: \(creados.count) - Unidos: \(unidos.count)")
        
        // Avisamos a la pantalla
        DispatchQueue.main.async {
            self.didUpdateData?()
        }
    }
    
    // Helpers para limpiar el código
    private func crearPartido(doc: QueryDocumentSnapshot) -> Partido {
        let data = doc.data()
        return Partido(
            id: doc.documentID,
            direccion: data["direccion"] as? String ?? "",
            dia: (data["dia"] as? Timestamp)?.dateValue() ?? Date(),
            posicion: data["posicion"] as? String ?? "",
            id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
            id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
            confirmacion_2: data["confirmacion_2"] as? String ?? ""
        )
    }
    
    private func crearSolicitud(doc: QueryDocumentSnapshot) -> Solicitud {
        let data = doc.data()
        return Solicitud(
            id_solicitud: doc.documentID,
            id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
            id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
            id_partido: data["id_partido"] as? String,
            aceptar_solicitado: data["aceptar_solicitado"] as? String,
            aceptar_solicitante: data["aceptar_solicitante"] as? String
        )
    }
    
    func cerrarSesion() {
        listenerPartidos?.remove()
        listenerSolicitudes?.remove()
        listenerPartidos = nil
        listenerSolicitudes = nil
        partidosMap.removeAll()
        solicitudesMap.removeAll()
        partidosCreados.removeAll()
        partidosUnidos.removeAll()
    }
}
