// PerfilClienteView.swift
// Equivalente SwiftUI de PerfilClienteViewController.
// Reemplaza: nombreTextField, apellidotxtfield, mailtxtfield,
//            posicionPickerView, posicionlbl, guardarbutton → savebutton.

import SwiftUI
import SkipFirebase
import FirebaseFirestore // Mantiene la compatibilidad nativa con las APIs de Firebase

import FirebaseAuth

struct PerfilClienteView: View {

    @Environment(\.dismiss) var dismiss

    // Campos (eran los UITextField del storyboard)
    @State private var nombre: String = ""      // era nombreTextField v9V-wO-k0o
    @State private var apellido: String = ""     // era apellidotxtfield x4R-Ag-2S8
    @State private var mail: String = ""         // era mailtxtfield 5tQ-MK-una
    @State private var posicion: String = "Cualquiera" // era posicionPickerView rQT-Sw-Xod

    @State private var isLoading: Bool = false
    @State private var guardado: Bool = false

    let posiciones = ["Arquero", "Defensor", "Mediocampista", "Delantero", "Cualquiera"]

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {

                // MARK: Título (era label "Mi perfil" Y0c-H8-a40)
                Text("Mi perfil")
                    .font(.system(size: 17))
                    .frame(maxWidth: .infinity, alignment: .center)

                // MARK: Nombre (era nombrelbl Ell-bd-k3N + nombreTextField v9V-wO-k0o)
                campoLabel("Nombre de usuario")
                TextField("Nombre", text: $nombre)
                    .textFieldStyle(.roundedBorder)

                // MARK: Apellido (era apellidolbl iQA-DY-pVf + apellidotxtfield x4R-Ag-2S8)
                campoLabel("Apellido")
                TextField("Apellido", text: $apellido)
                    .textFieldStyle(.roundedBorder)

                // MARK: Mail (era maillbl jhQ-TZ-QaQ + mailtxtfield 5tQ-MK-una)
                campoLabel("Mail")
                TextField("Email", text: $mail)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .disabled(true) // El email no se puede cambiar en Firebase Auth fácilmente
                    .foregroundStyle(.secondary)

                // MARK: Posición (era P3S-nK-AiB + 6n7-7z-wzG label + posicionPickerView)
                campoLabel("Posición preferente")

                // posicionlbl (era el label "Label" 6n7-7z-wzG)
                Text(posicion)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Posición", selection: $posicion) {
                    ForEach(posiciones, id: \.self) { p in
                        Text(p).tag(p)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 216)

                // Feedback guardado
                if guardado {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("¡Perfil guardado!").foregroundStyle(.green)
                    }
                }

                // MARK: Botón Guardar (era ipY-cM-h1P → savebutton IBAction)
                Button {
                    Task { await guardar() }
                } label: {
                    Text("Guardar")
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 47)
            .padding(.top, 113)
            .padding(.bottom, 40)
        }
        .navigationTitle("Mi Perfil")
        .overlay { if isLoading { ProgressView() } }
        .onAppear { cargarPerfil() }
    }

    // MARK: - Cargar perfil desde Firestore
    private func cargarPerfil() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Firestore.firestore().collection("usuarios").document(uid)
            .getDocument { snap, _ in
                let data = snap?.data() ?? [:]
                nombre   = data["nombre"]   as? String ?? ""
                apellido = data["apellido"] as? String ?? ""
                mail     = data["email"]    as? String ?? Auth.auth().currentUser?.email ?? ""
                posicion = data["posicion"] as? String ?? "Cualquiera"
                isLoading = false
            }
    }

    // MARK: - Guardar perfil en Firestore (era savebutton IBAction)
    private func guardar() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        try? await Firestore.firestore().collection("usuarios").document(uid).updateData([
            "nombre": nombre,
            "apellido": apellido,
            "posicion": posicion
        ])

        UserDefaults.standard.set(posicion, forKey: "posicionPreferente")
        isLoading = false
        guardado = true

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        guardado = false
    }

    @ViewBuilder
    private func campoLabel(_ texto: String) -> some View {
        Text(texto)
            .font(.system(size: 17))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
