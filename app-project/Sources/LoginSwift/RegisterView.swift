// RegisterView.swift
// Equivalente SwiftUI de RecordViewController.
// Reemplaza: usernameTextField, ApellidoTextField, emailTextField, passwordTextField,
//            confirmPasswordTextField, posicionPickerView, posicionlbl,
//            registrarButtonTapped, volverButtonTapped.

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RegisterView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    // Campos del formulario (eran todos los UITextField del storyboard)
    @State private var nombre: String = ""          // era usernameTextField 2Mg-YE-h0G
    @State private var apellido: String = ""         // era ApellidoTextField voe-Dk-NWW
    @State private var email: String = ""            // era emailTextField dq5-Mz-lDO
    @State private var password: String = ""         // era passwordTextField rA7-60-fjL
    @State private var confirmPassword: String = ""  // era confirmPasswordTextField cla-lN-6rv
    @State private var posicion: String = "Cualquiera" // era posicionPickerView gUc-9n-vol

    @State private var errorLocal: String = ""
    @State private var isLoading: Bool = false

    // Posiciones (era el UIPickerView con componentes)
    let posiciones = ["Arquero", "Defensor", "Mediocampista", "Delantero", "Cualquiera"]

    var body: some View {
        ScrollView {
            VStack(spacing: 7) {

                // MARK: Nombre (era label "ingresa nombre de usuario" + textField)
                campoLabel("Ingresá tu nombre de usuario")
                TextField("Nombre", text: $nombre)
                    .textFieldStyle(.roundedBorder)

                // MARK: Apellido (era label "ingresa el apellido" + textField)
                campoLabel("Ingresá el apellido")
                TextField("Apellido", text: $apellido)
                    .textFieldStyle(.roundedBorder)

                // MARK: Email (era label "ingresa el mail" + textField)
                campoLabel("Ingresá el mail")
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                // MARK: Password (era label "crea una contraseña" + textField)
                campoLabel("Creá una contraseña")
                SecureField("Contraseña", text: $password)
                    .textFieldStyle(.roundedBorder)

                // MARK: Confirmar password (era label "confirma la contraseña" + textField)
                campoLabel("Confirmá la contraseña")
                SecureField("Confirmar contraseña", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                // MARK: Posición (era label "posicion de preferente" + UIPickerView gUc-9n-vol)
                campoLabel("Posición preferente")

                // posicionlbl — era el label "Label" que mostraba la selección
                Text(posicion)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Posición", selection: $posicion) {
                    ForEach(posiciones, id: \.self) { pos in
                        Text(pos).tag(pos)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 216)

                // Error
                if !errorLocal.isEmpty {
                    Text(errorLocal)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // MARK: Botón Registrarse (era jav-yh-2Ro → registrarButtonTapped)
                Button {
                    Task { await registrar() }
                } label: {
                    Text("Registrarse")
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)

                // MARK: Botón Volver (era sSa-rM-eMX → volverButtonTapped)
                Button("Volver") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal, 47)
            .padding(.vertical, 36)
        }
        .navigationTitle("Crear Cuenta")
        .navigationBarBackButtonHidden(true)
        .overlay {
            if isLoading { ProgressView() }
        }
    }

    // MARK: - Lógica de registro
    private func registrar() async {
        errorLocal = ""

        guard !nombre.isEmpty, !apellido.isEmpty else {
            errorLocal = "Completá nombre y apellido."
            return
        }
        guard password == confirmPassword else {
            errorLocal = "Las contraseñas no coinciden."
            return
        }
        guard password.count >= 6 else {
            errorLocal = "La contraseña debe tener al menos 6 caracteres."
            return
        }

        isLoading = true

        // 1. Crear usuario en Firebase Auth
        await authVM.register(email: email, password: password)

        // 2. Guardar perfil en Firestore
        if let uid = Auth.auth().currentUser?.uid {
            try? await Firestore.firestore().collection("usuarios").document(uid).setData([
                "nombre": nombre,
                "apellido": apellido,
                "email": email,
                "posicion": posicion
            ])
            // Guardar posición preferente localmente para el filtro del mapa
            UserDefaults.standard.set(posicion, forKey: "posicionPreferente")
        }

        isLoading = false
    }

    // Helper para labels (era cada UILabel en el storyboard)
    @ViewBuilder
    private func campoLabel(_ texto: String) -> some View {
        Text(texto)
            .font(.system(size: 17))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
