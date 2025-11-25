//
//  RecordViewController.swift

import FirebaseFirestore
import FirebaseAuth
import Foundation
import UIKit

class RecordViewController: UIViewController, UITextFieldDelegate
{ // Conforma UITextFieldDelegate

    @IBOutlet weak var posicionPickerView: UIPickerView!
    @IBOutlet weak var ApellidoTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var posicionlbl: UILabel!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var registrarButton: UIButton!
    let posiciones =
    ["delantero","atacante","mediafield","defensa","portero"]
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RecordViewController viewDidLoad se ha llamado")
        posicionPickerView.delegate = self
        posicionPickerView.dataSource = self
        // Cualquier configuración inicial

        // Asigna el delegado de los UITextField a este ViewController
        usernameTextField.delegate = self
        emailTextField.delegate = self
        ApellidoTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        emailTextField.keyboardType = .emailAddress
    }

    @IBAction func registrarButtonTapped(_ sender: UIButton) {
        print("Botón 'Registrarse' pulsado")
        guard let username = usernameTextField.text, !username.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            
            mostrarAlerta(titulo: "Error", mensaje: "Por favor, completa todos los campos.")
            return
        }

        if password != confirmPassword {
            
            mostrarAlerta(titulo: "Error", mensaje: "Las contraseñas no coinciden.")
            return
        }

        // Llamada a la función para guardar el nuevo usuario en Firebase
        guardarNuevoUsuario(username: username, email: email, password: password)
    }

    // Función para guardar el nuevo usuario en Firebase Authentication y Firestore
    func guardarNuevoUsuario(username: String, email: String, password: String) {
        let db = Firestore.firestore()

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    
                    print("Error al crear usuario en Firebase Auth: \(error.localizedDescription)")
                    print("Detalles del error completo: \(error)") // Agrega esta línea
                    self.mostrarAlerta(titulo: "Error", mensaje: "Error al crear la cuenta: \(error.localizedDescription)")
                    return
                }
            }

            if let user = authResult?.user {
                let uid = user.uid
                let apellido = self.ApellidoTextField.text ?? ""
                let posicion = self.posicionlbl.text ?? ""
                let userData: [String: Any] = [
                    "uid": uid,
                    "nombre": username,
                    "apellido": apellido,
                    "email": email,
                    "posicion_preferente": posicion
                ]

                db.collection("Jugadores").document(user.uid).setData(userData) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            print("Error al guardar información del usuario en Firestore: \(error.localizedDescription)")
                            self.mostrarAlerta(titulo: "Error", mensaje: "Error al guardar la información del usuario.")
                            return
                        }
                    }
                    print("Usuario guardado exitosamente en Firestore.")
                    DispatchQueue.main.async {
                        self.mostrarAlerta(titulo: "Éxito", mensaje: "Cuenta creada exitosamente.") { _ in
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }

    @IBAction func volverButtonTapped(_ sender: UIButton) {
        print("Botón 'Volver' pulsado")
        dismiss(animated: true, completion: nil)
    }

    // Función para mostrar alertas al usuario
    func mostrarAlerta(titulo: String, mensaje: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let accionOK = UIAlertAction(title: "OK", style: .default, handler: completion)
        alerta.addAction(accionOK)
        present(alerta, animated: true, completion: nil)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Cierra el teclado del textField actual
        return true
    }
}
extension RecordViewController : UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return posiciones.count
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return posiciones[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        posicionlbl.text = posiciones[row]
    }
}


