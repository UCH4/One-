//
//  SolicitudViewController.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 08/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SwiftKeychainWrapper

class SolicitudViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
  
    
    // MARK: - Función para mostrar alerta de confirmación
    func mostrarConfirmacionDeAceptacion(jugador: Jugador, completion: @escaping ((UIAlertAction) -> Void)) {
        let alerta = UIAlertController(
            title: "¿Quieres aceptar al jugador \(jugador.nombre)?",
            message: "Nombre: \(jugador.nombre)\nMail: \(jugador.mail)\nPosición: \(jugador.posicion) \napellido: \(jugador.apellido)",
            preferredStyle: .alert
        )
        
        
        let aceptaAction = UIAlertAction(title: "Aceptar", style: .default, handler: completion)
        let cancelaAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alerta.addAction(aceptaAction)
        alerta.addAction(cancelaAction)
        
        // Esto debe estar dentro de un UIViewController
        self.present(alerta, animated: true)
    }

    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Variables
    private let db = Firestore.firestore()
    var partidoId: String!                 // solo el id del partido
    var partido :HomeViewController.Partido?
    private var solicitudes:[Solicitud] = []  // acá vamos a guardar todas las solicitudes
    
    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        print("abrio correctameente")
        print("partidoId: \(partidoId ?? "nulo")")
        
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .systemBackground
        title = "Solicitudes"
        
        // Elegimos de dónde tomar el id del partido
        if let id = partidoId {
            fetchSolicitudes(for: id)
        } else if let partido = partido {
            fetchSolicitudes(for: partido.id)
        } else {
            print(" No se recibió partido ni partidoId")
        }
    }

    // MARK: - Métodos de la tabla
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return solicitudes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SolicitudCell", for: indexPath)
        
        // Configuración de selección (color de fondo)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.red
        cell.selectedBackgroundView = backgroundView
        
        let solicitud = solicitudes[indexPath.row]
        
        //  Acá usamos la info del jugador si ya está cargada
        if let jugador = solicitud.jugadorInfo {
            cell.textLabel?.text = "Jugador: \(jugador.nombre)"
            cell.detailTextLabel?.text = "Posición: \(jugador.posicion)"
        } else {
            // Fallback si todavía no tenemos datos del jugador
            cell.textLabel?.text = "Jugador: \(solicitud.id_jugador_solicitado)"
            cell.detailTextLabel?.text = "Aceptado: \(solicitud.aceptar_solicitante ?? "Pendiente")"
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let solicitud = solicitudes[indexPath.row]
        
        // Verificamos que exista la info del jugador
        if let jugador = solicitud.jugadorInfo {
            mostrarConfirmacionDeAceptacion(jugador: jugador) { _ in
                //  Acá va lo que querés hacer si acepta
                print("Jugador \(jugador.nombre) aceptado en la solicitud \(solicitud.id_solicitud)")
                
                // Ejemplo: actualizar Firestore
                self.db.collection("Solicitudes").document(solicitud.id_solicitud).updateData([
                    "aceptar_solicitante": "true"
                ]) { error in
                    if let error = error {
                        print("Error al aceptar solicitud: \(error.localizedDescription)")
                    } else {
                        print("Solicitud actualizada correctamente")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } else {
            print("No hay info del jugador en esta solicitud")
        }
    }

    
    // MARK: - Firestore
    private func fetchSolicitudes(for partidoId: String) {
        // Primero traemos todas las solicitudes relacionadas al partido
        db.collection("Solicitudes")
            .whereField("id_partido", isEqualTo: partidoId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error al obtener solicitudes: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                // Mapeamos cada documento de Firestore a nuestro struct Solicitud
                self.solicitudes = documents.compactMap { doc -> Solicitud? in
                    let data = doc.data()
                    return Solicitud(
                        id_solicitud: doc.documentID,
                        id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
                        id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
                        id_partido: data["id_partido"] as? String,
                        aceptar_solicitado: data["aceptar_solicitado"] as? String,
                        aceptar_solicitante: data["aceptar_solicitante"] as? String,
                        jugadorInfo: nil // por ahora no tenemos datos del jugador
                    )
                }
                
                //Ahora traemos TODOS los jugadores para poder cruzar con las solicitudes
                self.db.collection("Jugadores").addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error al obtener jugadores: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else { return }
                    
                    for doc in documents {
                        let data = doc.data()
                        
                        // Creamos una instancia del jugador con sus datos
                        let jugador = Jugador(
                            id: doc.documentID,
                            nombre: data["nombre"] as? String ?? "",
                            mail: data["email"] as? String ?? "",
                            posicion: data["posicion_preferente"] as? String ?? "",
                            apellido: data["apellido"] as? String ?? ""
                        )
                        
                        // Buscamos en las solicitudes cuál corresponde a este jugador
                        for (index, solicitud) in self.solicitudes.enumerated() {
                            if solicitud.id_jugador_solicitado == doc.documentID {
                                self.solicitudes[index].jugadorInfo = jugador
                            }
                        }
                    }
                    
                    // Recargamos la tabla en el hilo principal
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
    }
}


// MARK: - Structs
struct Solicitud {
    var id_solicitud: String
    var id_jugador_solicitante: String
    var id_jugador_solicitado: String
    var id_partido: String?
    var aceptar_solicitado: String?
    var aceptar_solicitante: String?
    var jugadorInfo: Jugador?   //  Datos del jugador relacionados
}

struct Jugador  {
    var id: String
    var nombre: String
    var mail: String
    var posicion: String
    var apellido: String
}
