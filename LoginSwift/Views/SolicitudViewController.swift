//
//  SolicitudViewController.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 08/05/2025.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class SolicitudViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()

    // Datos de navegación
    var partidoId: String!
    var partido: Partido?

    // Estado
    private var solicitudes: [Solicitud] = []

    // Servicio optimizado con cache/stop
    private let service = FirebasePartidosService()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        title = "Solicitudes"

        // Elegimos de dónde tomar el id del partido
        if let id = partidoId {
            cargarSolicitudes(partidoId: id)
        } else if let partido = partido {
            cargarSolicitudes(partidoId: partido.id)
        } else {
            print("No se recibió partido ni partidoId")
        }
    }

    private func cargarSolicitudes(partidoId: String) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let items = try await service.obtenerSolicitudes(partidoId: partidoId)
                self.solicitudes = items
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Error al cargar solicitudes: \(error)")
            }
        }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        solicitudes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SolicitudCell", for: indexPath)
        let solicitud = solicitudes[indexPath.row]

        if let jugador = solicitud.jugadorInfo {
            cell.textLabel?.text = "Jugador: \(jugador.nombre)"
            cell.detailTextLabel?.text = "Posición: \(jugador.posicion)"
        } else {
            cell.textLabel?.text = "Jugador: \(solicitud.id_jugador_solicitado)"
            cell.detailTextLabel?.text = "Aceptado: \(solicitud.aceptar_solicitante ?? "Pendiente")"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let solicitud = solicitudes[indexPath.row]

        Task {
            do {
                try await service.actualizarEstadoSolicitud(id: solicitud.id_solicitud, aceptarSolicitante: "true", aceptarSolicitado: nil)
                // Opcional: refrescar la lista
                if let id = partidoId {
                    await cargarYRecargar(partidoId: id)
                } else if let p = partido {
                    await cargarYRecargar(partidoId: p.id)
                }
            } catch {
                print("Error al actualizar solicitud: \(error)")
            }
        }
    }

    private func cargarYRecargar(partidoId: String) async {
        do {
            let items = try await service.obtenerSolicitudes(partidoId: partidoId)
            self.solicitudes = items
            DispatchQueue.main.async { self.tableView.reloadData() }
        } catch {
            print("Error al recargar solicitudes: \(error)")
        }
    }
}
