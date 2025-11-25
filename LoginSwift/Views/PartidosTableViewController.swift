//
//  PartidosTableViewController.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 16/07/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class PartidosTableViewController: UITableViewController {
    
    struct Solicitud {
        
        var  id_solicitud: String
        var id_jugador_solicitante: String
        var  id_jugador_solicitado: String
        var id_partido: String?
        var aceptar_solicitado:String?
        var aceptar_solicitante:String?
    }

    struct Partido {
        var id: String
        var direccion: String
        var dia: Date
        var posicion: String
        var id_jugador_solicitante: String
        var id_jugador_solicitado: String
    }
    @IBOutlet weak var filtroSwitch: UISwitch!
    var solicitudes: [Solicitud] = []
    var partidos: [Partido] = []
    var posicoinPreferente: String?
    var mostrarSoloCoincidientes = false

    override func viewDidLoad() {
        super.viewDidLoad()
        obtenerPosicionDelUsuario()
    }
func obtenerPosicionDelUsuario() {
    guard let uid = Auth.auth().currentUser?.uid else {
        print("error al obtener el uid")
        return
    }
    let db = Firestore.firestore()
    db.collection("Jugadores").document(uid).getDocument { snapshot, error in
        if let data = snapshot?.data(),
           let posicion = data ["posicion_preferente"]as? String{
            self.posicoinPreferente = posicion
            print("se obtuvo correctamente la posicion preferente del usuario: \(posicion)")
            self.fetchPartidos()
        }else {
            print("no se pudo obtener la posicion preferente del usuario")
            self.fetchPartidos()
        }
    }
    }
    func fetchPartidos() {
        
        let db = Firestore.firestore()
        
        db.collection("Partidos").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error al escuchar cambios: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No hay documentos encontrados")
                return
            }
            
            var resultados: [Partido] = []
            
            for doc in documents {
                let data = doc.data()
                
                guard let direccion = data["direccion"] as? String,
                      let timestamp = data["dia"] as? Timestamp,
                      let posicion = data["posicion"] as? String,
                      let solicitante = data["id_jugador_solicitante"] as? String,
                      let solicitado = data["id_jugador_solicitado"] as? String
                else {
                    print("Documento con campos inválidos: \(doc.documentID)")
                    continue
                }
                
                let dia = timestamp.dateValue()
                
             

                
                if solicitado.isEmpty{
                    
                    if dia < Date(){
                        db.collection( "Partidos").document(doc.documentID).delete()
                        print("se borro ya que no se encontro un jugador solicitado antes del partido \(dia)")
                        continue
                    }
                    
                    let partido = Partido(
                        id: doc.documentID,
                        direccion: direccion,
                        dia: dia,
                        posicion: posicion,
                        id_jugador_solicitante: solicitante,
                        id_jugador_solicitado: solicitado
                    )
                    if self.mostrarSoloCoincidientes{
                        if posicion == self.posicoinPreferente{
                            resultados.append(partido)
                        }
                    }else {
                        resultados.append(partido)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.partidos = resultados
                self.tableView.reloadData()
            }
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partidos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let partido = partidos[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartidoCell", for: indexPath)

        cell.textLabel?.text = "\(partido.direccion) - \(partido.posicion.capitalized)"
        cell.detailTextLabel?.text = formatearFecha(partido.dia)

        return cell
    }

    func formatearFecha(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let partido = partidos[indexPath.row]
        mostrarConfirmacionParaUnirse(partido: partido)
    }
    func unirseAlPartido(_ partido: Partido) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Verifico si ya existe una solicitud del mismo usuario para este partido
        db.collection("Solicitudes")
            .whereField("id_partido", isEqualTo: partido.id)
            .whereField("id_jugador_solicitado", isEqualTo: uid)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error obteniendo solicitudes: \(err)")
                    self.mostrarAlerta(titulo: "Error", mensaje: "No se pudo verificar solicitudes previas")
                    return
                }
                
                if let snapshot = querySnapshot, snapshot.documents.count > 0 {
                    print("Ya existe una solicitud para este partido")
                    self.mostrarAlerta(titulo: "Aviso", mensaje: "Ya estás unido al partido")
                    return
                }
                
                // No hay solicitudes previas → creo una nueva
                let solicitudRef = db.collection("Solicitudes").document()
                let solicitudData: [String: Any] = [
                    "id_solicitud": solicitudRef.documentID,
                    "id_jugador_solicitado": uid,
                    "id_jugador_solicitante": partido.id_jugador_solicitante,
                    "id_partido": partido.id,
                    "aceptar_solicitado": "pendiente",
                    "aceptar_solicitante": "pendiente"
                ]
                
                solicitudRef.setData(solicitudData) { error in
                    if let error = error {
                        print("Error al crear solicitud: \(error)")
                        self.mostrarAlerta(titulo: "Error", mensaje: "No se pudo unir al partido")
                        return
                    }
                    
                    print("Solicitud creada en: Solicitudes/\(solicitudRef.documentID)")
                    
                    // Actualizo el partido con el jugador solicitado
                  //  db.collection("Partidos").document(partido.id).updateData([
                    //    "id_jugador_solicitado": uid
                   // ]) { error in
                        if let error = error {
                            print("Error al actualizar partido: \(error)")
                          self.mostrarAlerta(titulo: "Error", mensaje: "No se pudo actualizar el partido")
                       } else {
                            print("Jugador unido correctamente al partido")
                         self.mostrarAlerta(titulo: "Éxito", mensaje: "Te uniste al partido correctamente")	
                       }
             //       }
                }
            }
    }

    @IBAction func switchCambiado(_ sender: UISwitch) {
        mostrarSoloCoincidientes = sender.isOn
        fetchPartidos()
    }
    func mostrarAlerta(titulo: String, mensaje: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let accionOK = UIAlertAction(title: "OK", style: .default, handler: completion)
        alerta.addAction(accionOK)
        present(alerta, animated: true, completion: nil)
    }
    func mostrarConfirmacionParaUnirse(partido: Partido) {
        let alerta = UIAlertController(
            title: "¿Unirte al partido?",
            message: "Dirección: \(partido.direccion)\nPosición: \(partido.posicion.capitalized)\nFecha: \(formatearFecha(partido.dia))",
            preferredStyle: .alert
        )

        let unirseAction = UIAlertAction(title: "Sí, quiero unirme", style: .default) { _ in
            self.unirseAlPartido(partido)
        }

        let cancelarAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        alerta.addAction(unirseAction)
        alerta.addAction(cancelarAction)

        present(alerta, animated: true, completion: nil)
    }

}

