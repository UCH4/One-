import UIKit
import FirebaseAuth
import FirebaseFirestore
import SwiftKeychainWrapper

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - UI
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var MitableView: UITableView!  // Tabla partidos creados
    @IBOutlet weak var tableView: UITableView!    // Tabla partidos unidos
    @IBOutlet weak var MyPerfilButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    // MARK: - MODELOS
    struct Solicitud : Equatable, Hashable{
        var id_solicitud: String
        var id_jugador_solicitante: String
        var id_jugador_solicitado: String
        var id_partido: String?
        var aceptar_solicitado: String?
        var aceptar_solicitante: String?
    }

    struct Partido : Equatable, Hashable{
        var id: String
        var direccion: String
        var dia: Date
        var posicion: String
        var id_jugador_solicitante: String
        var id_jugador_solicitado: String
        var confirmacion_2: String
    }

    struct PartidoConSolicitud : Equatable, Hashable{
        var partido: Partido
        var solicitud: Solicitud?
        

    }

    // MARK: - Variables
    private let db = Firestore.firestore()
    private var listenerPartidos: ListenerRegistration?
    private var listenerSolicitudes: ListenerRegistration?

    private var partidosMap: [String: Partido] = [:]      // id_partido -> Partido
    private var solicitudesMapPorPartido: [String: [Solicitud]] = [:]     // id_partido → [Solicitudes]

    var partidosUnidos: [PartidoConSolicitud] = []
    var partidosCreados: [PartidoConSolicitud] = []

    //  UID persistente (guardado en Keychain)
    var id_jugador: String? {
        if let uid = Auth.auth().currentUser?.uid {
            KeychainWrapper.standard.set(uid, forKey: "userUID")
            return uid
        } else if let savedUID = KeychainWrapper.standard.string(forKey: "userUID") {
            return savedUID
        }
        return nil
    }
    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        print(" HomeViewController viewDidLoad")

        tableView.delegate = self
        tableView.dataSource = self
        MitableView.delegate = self
        MitableView.dataSource = self

        tableView.alwaysBounceVertical = true
        MitableView.alwaysBounceVertical = true

        if let uid = id_jugador {
            welcomeLabel.text = "Bienvenido \(uid.prefix(5))..."
        }
    }

    //  Cuando la vista aparece de nuevo (después de volver del SolicitudViewController)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(" HomeViewController viewWillAppear → iniciando listeners")
        escucharCambios()
    }

    //  Cuando la vista deja de estar visible
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(" HomeViewController viewWillDisappear → removiendo listeners")
        listenerPartidos?.remove()
        listenerSolicitudes?.remove()
    }

    // ===========================================================
    //  ESCUCHAR CAMBIOS DE PARTIDOS Y SOLICITUDES DEL USUARIO
    //  Y ACTUALIZAR LOS PARTIDOS CORRESPONDIENTES
    // ===========================================================
    func escucharCambios() {
        guard let uid = id_jugador else {
            print(" No hay usuario autenticado, no se escuchan datos.")
            return
        }

        listenerPartidos?.remove()
        listenerSolicitudes?.remove()

        //  Escuchar partidos creados por el usuario (sin depender de solicitudes)
        listenerPartidos = db.collection("Partidos")
            .whereField("id_jugador_solicitante", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print(" Error al escuchar tus partidos creados: \(error.localizedDescription)")
                    return
                }

                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    let partido = Partido(
                        id: doc.documentID,
                        direccion: data["direccion"] as? String ?? "",
                        dia: (data["dia"] as? Timestamp)?.dateValue() ?? Date(),
                        posicion: data["posicion"] as? String ?? "",
                        id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
                        id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
                        confirmacion_2: data["confirmacion_2"] as? String ?? ""
                    )
                    self.partidosMap[partido.id] = partido
                }

                print(" Partidos creados escuchados: \(snapshot?.documents.count ?? 0)")
                self.sincronizarDatos()
            }

        //  Escuchar solicitudes donde el usuario esté involucrado
        listenerSolicitudes = db.collection("Solicitudes")
            .whereFilter(Filter.orFilter([
                Filter.whereField("id_jugador_solicitante", isEqualTo: uid),
                Filter.whereField("id_jugador_solicitado", isEqualTo: uid)
            ]))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print(" Error al escuchar solicitudes: \(error.localizedDescription)")
                    return
                }

                var nuevasSolicitudesPorPartido: [String: [Solicitud]] = [:]

                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    guard let idPartido = data["id_partido"] as? String else { continue }

                    let solicitud = Solicitud(
                        id_solicitud: doc.documentID,
                        id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
                        id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
                        id_partido: idPartido,
                        aceptar_solicitado: data["aceptar_solicitado"] as? String,
                        aceptar_solicitante: data["aceptar_solicitante"] as? String
                    )

                    nuevasSolicitudesPorPartido[idPartido, default: []].append(solicitud)
                }

                self.solicitudesMapPorPartido = nuevasSolicitudesPorPartido
                print(" Solicitudes escuchadas: \(nuevasSolicitudesPorPartido.count) partidos con solicitudes")

                //  Obtener los partidos asociados a las solicitudes (uniones)
                let idsPartidos = Array(nuevasSolicitudesPorPartido.keys)
                guard !idsPartidos.isEmpty else {
                    self.sincronizarDatos()
                    return
                }

                // Escuchar solo esos partidos unidos
                self.db.collection("Partidos")
                    .whereField(FieldPath.documentID(), in: idsPartidos)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print(" Error al obtener partidos unidos: \(error.localizedDescription)")
                            return
                        }

                        for doc in snapshot?.documents ?? [] {
                            let data = doc.data()
                            let partido = Partido(
                                id: doc.documentID,
                                direccion: data["direccion"] as? String ?? "",
                                dia: (data["dia"] as? Timestamp)?.dateValue() ?? Date(),
                                posicion: data["posicion"] as? String ?? "",
                                id_jugador_solicitante: data["id_jugador_solicitante"] as? String ?? "",
                                id_jugador_solicitado: data["id_jugador_solicitado"] as? String ?? "",
                                confirmacion_2: data["confirmacion_2"] as? String ?? ""
                            )
                            self.partidosMap[partido.id] = partido
                        }

                        print(" Partidos unidos escuchados: \(snapshot?.documents.count ?? 0)")
                        self.sincronizarDatos()
                    }
            }
    }


    // ===========================================================
    //  COMBINAR DATOS Y REFRESCAR UI
    // ===========================================================
    private func sincronizarDatos() {
        guard let uid = id_jugador else { return }

        var nuevosCreados: [PartidoConSolicitud] = []
        var nuevosUnidos: [PartidoConSolicitud] = []

        for (id, partido) in partidosMap {
            let solicitudes = solicitudesMapPorPartido[id] ?? []

            // Si el usuario es el creador del partido → Tabla "Creados"
            if partido.id_jugador_solicitante == uid {
                let ultimaSolicitud = solicitudes.sorted(by: { $0.id_solicitud > $1.id_solicitud }).first
                nuevosCreados.append(PartidoConSolicitud(partido: partido, solicitud: ultimaSolicitud))
            }
            // Si el usuario es jugador solicitado en alguna solicitud → Tabla "Unidos"
            else if let solicitud = solicitudes.first(where: { $0.id_jugador_solicitado == uid }) {
                nuevosUnidos.append(PartidoConSolicitud(partido: partido, solicitud: solicitud))
            }
        }

        partidosCreados = nuevosCreados
        partidosUnidos = nuevosUnidos

        DispatchQueue.main.async {
            print(" UI Actualizada → Creados: \(self.partidosCreados.count) | Unidos: \(self.partidosUnidos.count)")
            self.MitableView.reloadData()
            self.tableView.reloadData()
        }
    }



    // ===========================================================
    //  TableView DataSource
    // ===========================================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableView == self.tableView) ? partidosUnidos.count : partidosCreados.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartidoCell", for: indexPath)
        let item = (tableView == self.tableView) ? partidosUnidos[indexPath.row] : partidosCreados[indexPath.row]
        let partido = item.partido
        let solicitud = item.solicitud

        // Texto visible
        cell.textLabel?.text = "\(partido.direccion) - \(partido.posicion.capitalized)"
        cell.detailTextLabel?.text = formatearFecha(partido.dia)

        // Color según estado
        if let s = solicitud {
            if s.aceptar_solicitante == "true" && s.aceptar_solicitado == "true" {
                cell.backgroundColor = .systemGreen
            } else if s.aceptar_solicitante == "true" || s.aceptar_solicitado == "true" {
                cell.backgroundColor = .systemYellow
            } else if s.aceptar_solicitado == "false" {
                cell.backgroundColor = .systemRed
            } else {
                cell.backgroundColor = .systemGray5
            }
        } else {
            cell.backgroundColor = .systemGray5
        }

        return cell

    }

    // ===========================================================
    //  Interacciones con celdas
    // ===========================================================
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if tableView == self.tableView {
            mostrarConfirmacionParaSalirse(partidoConSolicitud: partidosUnidos[indexPath.row])
        } else {
            let partido = partidosCreados[indexPath.row].partido
            irAVerSolicitantes(partido: partido)
        }
    }

    // ===========================================================
    //  Lógica de aceptación o salida
    // ===========================================================
    func mostrarConfirmacionParaSalirse(partidoConSolicitud: PartidoConSolicitud) {
        guard let solicitud = partidoConSolicitud.solicitud else {
                 mostrarAlerta(titulo: "Error", mensaje: "No se encontró la solicitud asociada.")
                 return
             }

             let partido = partidoConSolicitud.partido
             let alerta = UIAlertController(
                 title: "Gestionar solicitud",
                 message: "Dirección: \(partido.direccion)\nPosición: \(partido.posicion.capitalized)",
                 preferredStyle: .alert
             )

             alerta.addAction(UIAlertAction(title: "Confirmar", style: .default) { _ in
                 self.modificarSolicitud(solicitudId: solicitud.id_solicitud, nuevoEstado: "true")
             })
             alerta.addAction(UIAlertAction(title: "Salir", style: .destructive) { _ in
                 self.modificarSolicitud(solicitudId: solicitud.id_solicitud, nuevoEstado: "false")
             })
             alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

             present(alerta, animated: true)
    }
    func modificarSolicitud(solicitudId: String, nuevoEstado: String) {
        db.collection("Solicitudes").document(solicitudId).updateData([
            "aceptar_solicitado": nuevoEstado,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print(" Error al modificar solicitud: \(error.localizedDescription)")
            } else {
                print(" Solicitud \(solicitudId) actualizada correctamente")

                //  Verificar si ambos aceptaron → Confirmar partido
                self.db.collection("Solicitudes").document(solicitudId).getDocument { doc, _ in
                    guard let data = doc?.data(),
                          let idPartido = data["id_partido"] as? String,
                          let aceptarSolicitante = data["aceptar_solicitante"] as? String,
                          let aceptarSolicitado = data["aceptar_solicitado"] as? String,
                          let idJugadorSolicitado = data["id_jugador_solicitado"] as? String
                    else { return }

                    if aceptarSolicitante == "true", aceptarSolicitado == "true" {
                        //  Ambos aceptaron → actualizamos el partido
                        self.db.collection("Partidos").document(idPartido).updateData([
                            "id_jugador_solicitado": idJugadorSolicitado,
                            "confirmacion_2": "true"
                        ]) { err in
                            if let err = err {
                                print(" Error al confirmar partido: \(err.localizedDescription)")
                            } else {
                                print(" Partido confirmado con jugador \(idJugadorSolicitado)")
                            }
                        }
                    }
                }
            }
        }
    }



    // MARK: - Helpers
    func formatearFecha(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }

    func irAVerSolicitantes(partido: Partido) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SolicitudViewController") as? SolicitudViewController {
            vc.partidoId = partido.id
            navigationController?.pushViewController(vc, animated: true)
        }
    }




@IBAction func irPerfilClienteTapped(_ sender: UIButton) {
    performSegue(withIdentifier: "mostrarperfilcliente", sender: self)
}

@IBAction func searchTapped(_ sender: UIButton) {
    print("Buscar faltante")
}

@IBAction func logoutTapped(_ sender: UIButton) {
    do {
        try Auth.auth().signOut()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            view.window?.windowScene?.keyWindow?.rootViewController = vc
            view.window?.windowScene?.keyWindow?.makeKeyAndVisible()
        }
    } catch {
        print("Error al cerrar sesión: \(error.localizedDescription)")
    }
}
}


