//
//  ShareViewController.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 02/07/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SwiftKeychainWrapper
import Foundation

class ShareViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var fechapicker: UIDatePicker!
    @IBOutlet weak var chooseposition: UIPickerView!
    @IBOutlet weak var publicarbusqueda: UIButton!
    @IBOutlet weak var postionselectlabel: UILabel!
    @IBOutlet weak var direcciontextfield: UITextField!
    
    let positions = ["delantero", "atacante", "mediafield", "defensa", "portero"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chooseposition.delegate = self
        chooseposition.dataSource = self
        direcciontextfield.delegate = self
    }
    
    // MARK: - Acción del botón
    @IBAction func publicarbusquedatapped(_ sender: Any) {
        publicacionpartido()
    }

    // MARK: - Función para crear y guardar el partido en Firestore
    func publicacionpartido() {
        guard let user = Auth.auth().currentUser?.uid else {
            print(" No se encontró el usuario")
            return
        }
        
        let db = Firestore.firestore()
        let direccion = direcciontextfield.text ?? ""
        let fecha = fechapicker.date
        let posicion = postionselectlabel.text ?? ""
        
        if direccion.isEmpty || posicion.isEmpty {
            mostrarAlerta(titulo: "Error", mensaje: "Faltan completar campos")
            return
        }
        
        // Generar ID automático del partido
        let partidoRef = db.collection("Partidos").document()
        let partidoID = partidoRef.documentID
        
        let partidoData: [String: Any] = [
            "direccion": direccion,
            "dia": Timestamp(date: fecha),
            "posicion": posicion,
            "id_jugador_solicitante": user,
            "id_jugador_solicitado": "",
            "id_partido": partidoID,
            "confirmacion_2":"pendiente"
        ]
        
        partidoRef.setData(partidoData) { error in
            if let error = error {
                print(" Error al guardar el partido: \(error.localizedDescription)")
            } else {
                print(" Partido creado con ID: \(partidoID)")
                self.mostrarAlerta(titulo: "¡Listo!", mensaje: "Tu búsqueda fue publicada correctamente.")
            }
        }
    }
    
    // MARK: - Mostrar alerta
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alerta, animated: true, completion: nil)
    }
    
    // MARK: - Ocultar teclado
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PickerView
extension ShareViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return positions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return positions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        postionselectlabel.text = positions[row]
    }
}

