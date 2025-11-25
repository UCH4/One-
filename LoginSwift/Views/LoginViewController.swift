//
//  ViewController.swift
//  LoginSwift
//
//  Created by Victor Roldan on 4/05/22.
// EL CÓDIGO DE LA APP BASE NO CUMPLE CON NINGÚN PATRÓN DE ARQUITECTURA

import UIKit
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseFirestore
class LoginViewController: UIViewController, UITextFieldDelegate { // Conforma UITextFieldDelegate

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var eyeButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    private var defaults = UserDefaults.standard
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("LoginViewController viewDidLoad se ha llamado")
        layoutLoginButton()
        layoutTextFields() 
        loginButton.addTarget(self, action: #selector(loginButtonPressed), for: .touchUpInside)
        loadingIndicator.isHidden = true // Inicialmente oculto

        // Asigna el delegado de los UITextField a este ViewController
        emailTextField.keyboardType = .emailAddress
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    private func layoutTextFields() {
        let paddingLeftEmail = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 45))
        let paddingLeftPwd = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 45))
        emailTextField.leftView = paddingLeftEmail
        passwordTextField.leftView = paddingLeftPwd
        emailTextField.leftViewMode = .always
        passwordTextField.leftViewMode = .always
        emailTextField.layer.cornerRadius = 5.0
        passwordTextField.layer.cornerRadius = 5.0

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray.withAlphaComponent(0.5)]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray.withAlphaComponent(0.5)]
        )
    }

    private func layoutLoginButton() {
        let color1: UIColor = UIColor(red: 105/255, green: 161/255, blue: 248/255, alpha: 1.0)
        let color2: UIColor = UIColor(red: 68/255, green: 107/255, blue: 234/255, alpha: 1.0)

        loginButton.tintColor = .white
        loginButton.layer.cornerRadius = 5
        loginButton.clipsToBounds = true

        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = loginButton.frame.size
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        loginButton.layer.addSublayer(gradientLayer)
    }

    @IBAction func eyeButtonPressed(_ sender: Any) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry

        let icon: String = passwordTextField.isSecureTextEntry ? "eye.fill" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: icon), for: .normal)
    }
    
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            self.mostrarAlerta(titulo: "Correo faltante", mensaje: "Por favor, ingresa un correo válido.")
            return
        }

        // Validar formato del correo
        guard isValidEmail(email) else {
            self.mostrarAlerta(titulo: "Formato incorrecto", mensaje: "El correo ingresado no tiene un formato válido.")
            return
        }

        //  Consultar si existe en Firestore
        db.collection("Jugadores").whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
            if let error = error {
                print(" Error al consultar Firestore: \(error.localizedDescription)")
                self.mostrarAlerta(titulo: "Error", mensaje: "Ocurrió un error al buscar tu cuenta.")
                return
            }

            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                self.mostrarAlerta(titulo: "Cuenta no encontrada", mensaje: "No existe una cuenta asociada a \(email).")
                return
            }

            //  Si existe, enviamos el correo de restablecimiento
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print(" Error al enviar el correo: \(error.localizedDescription)")
                    self.mostrarAlerta(titulo: "Error", mensaje: "No se pudo enviar el correo: \(error.localizedDescription)")
                    return
                }

                print(" Se envió un enlace de restablecimiento a \(email)")
                self.mostrarAlerta(
                    titulo: "Correo enviado",
                    mensaje: "Te enviamos un enlace para restablecer tu contraseña a \(email).\nRevisá tu bandeja de entrada o la carpeta de Spam."
                )
            }
        }
    }

    //  Validación de formato de correo
    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format:"SELF MATCHES %@", regex)
        return pred.evaluate(with: email)
    }


    @objc func loginButtonPressed() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            self.mostrarAlerta(titulo: "error al completar los campos", mensaje: "Por favor, completa todos los campos.")
            return
        }

        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true

            if let error = error {
                print("Error al iniciar sesión en Firebase Auth: \(error.localizedDescription)")
                self.mostrarAlerta(titulo: "error al iniciar sesión", mensaje: "Error al iniciar sesión: \(error.localizedDescription)")

                return
            }

            // Si el inicio de sesión es exitoso
            if let user = authResult?.user { // Verifica que authResult?.user no sea nil
                print("Usuario \(user.uid) ha iniciado sesión exitosamente.")
                // Aquí puedes realizar la acción para navegar a la siguiente pantalla
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                    let navController = UINavigationController(rootViewController: homeVC)
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated: true, completion: nil)
                }

            } else {
                // Esto podría ocurrir si no hay error pero tampoco hay usuario (caso raro, pero posible)
                print("Error: No se recibió información del usuario después del inicio de sesión.")
                self.mostrarAlerta(titulo: "error informacion", mensaje: "Error desconocido al iniciar sesión.")
            }
        }
    }


    
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default))
        present(alerta, animated: true)
    }


    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Cierra el teclado del textField actual
        return true
    }
}
