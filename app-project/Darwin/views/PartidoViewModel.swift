// PartidoViewModel.swift
// Lógica de Firestore para partidos.
// Reemplaza el código de Firestore disperso en HomeViewController y PartidosTableViewController.

import SwiftUI
import SkipFirebase
import FirebaseFirestore // Mantiene la compatibilidad nativa con las APIs de Firebase

import FirebaseAuth

// MARK: - Modelo de datos
struct Partido: Identifiable, Codable {
    @DocumentID var id: String?
    var direccion: String
    var posicion: String
    var fecha: Date
    var creadorUID: String
    var estado: EstadoPartido

    enum EstadoPartido: String, Codable {
        case pendiente   // Amarillo
        case confirmado  // Verde
        case cancelado   // Rojo
    }
}

// MARK: - ViewModel
@MainActor
class PartidoViewModel: ObservableObject {

    @Published var partidos: [Partido] = []
    @Published var misPartidos: [Partido] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Posiciones disponibles (era el UIPickerView en ShareVC y RecordVC)
    let posiciones = ["Arquero", "Defensor", "Mediocampista", "Delantero", "Cualquiera"]

    deinit {
        listener?.remove()
    }

    // MARK: - Escucha partidos en tiempo real (era listener en HomeViewController)
    func escucharPartidos(filtrarPorPosicion: Bool = false) {
        listener?.remove()
        isLoading = true

        var query: Query = db.collection("partidos")
            .order(by: "fecha", descending: false)

        // era el filtroSwitch en PartidosTableViewController
        if filtrarPorPosicion, let uid = Auth.auth().currentUser?.uid {
            // Filtrar por posición preferente del usuario
            query = query.whereField("posicion", isEqualTo: obtenerPosicionUsuario(uid: uid))
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.partidos = snapshot?.documents.compactMap {
                    try? $0.data(as: Partido.self)
                } ?? []
            }
        }
    }

    // MARK: - Mis partidos (era MitableView en HomeViewController)
    func escucharMisPartidos() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("partidos")
            .whereField("creadorUID", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    self?.misPartidos = snapshot?.documents.compactMap {
                        try? $0.data(as: Partido.self)
                    } ?? []
                }
            }
    }

    // MARK: - Publicar partido (era publicarbusquedatapped en ShareViewController)
    func publicarPartido(direccion: String, posicion: String, fecha: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let nuevo = Partido(
            direccion: direccion,
            posicion: posicion,
            fecha: fecha,
            creadorUID: uid,
            estado: .pendiente
        )

        do {
            try db.collection("partidos").addDocument(from: nuevo)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Color por estado (era el código de color en las celdas)
    func colorParaPartido(_ partido: Partido) -> Color {
        switch partido.estado {
        case .confirmado: return .green.opacity(0.3)
        case .pendiente:  return .yellow.opacity(0.3)
        case .cancelado:  return .red.opacity(0.3)
        }
    }

    private func obtenerPosicionUsuario(uid: String) -> String {
        // En una implementación completa se lee de Firestore/UserDefaults
        return UserDefaults.standard.string(forKey: "posicionPreferente") ?? "Cualquiera"
    }
}
