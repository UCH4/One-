// ShareView.swift
// Equivalente SwiftUI de ShareViewController.
// Reemplaza: direcciontextfield, chooseposition (UIPickerView), fechapicker (UIDatePicker),
//            publicarbusqueda button → publicarbusquedatapped.

import SwiftUI

struct ShareView: View {

    @EnvironmentObject var partidoVM: PartidoViewModel
    @Environment(\.dismiss) var dismiss

    // era direcciontextfield
    @State private var direccion: String = ""

    // era chooseposition UIPickerView + postionselectlabel
    @State private var posicionSeleccionada: String = "Cualquiera"

    // era fechapicker UIDatePicker (modo dateAndTime)
    @State private var fechaSeleccionada: Date = Date()

    @State private var publicado: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {

                // MARK: Dirección de la cancha (era label + textField ceu-Ae-KSR)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dirección de la cancha")
                        .font(.headline)

                    TextField("Ej: Av. Corrientes 1234", text: $direccion)
                        .textFieldStyle(.roundedBorder)
                }

                // MARK: Posición del jugador faltante
                // era label "posicion del jugador faltante" + UIPickerView qXW-GK-t86 + postionselectlabel
                VStack(alignment: .leading, spacing: 8) {
                    Text("Posición del jugador faltante")
                        .font(.headline)

                    Text(posicionSeleccionada)
                        .foregroundStyle(Color.accentColor)
                        .font(.subheadline)

                    Picker("Posición", selection: $posicionSeleccionada) {
                        ForEach(partidoVM.posiciones, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }

                // MARK: Fecha y hora (era UIDatePicker uF1-sp-YfO, modo dateAndTime)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fecha y hora del partido")
                        .font(.headline)

                    DatePicker(
                        "Fecha",
                        selection: $fechaSeleccionada,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }

                // Feedback de éxito
                if publicado {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("¡Búsqueda publicada!")
                            .foregroundStyle(.green)
                    }
                }

                // MARK: Botón Publicar (era wri-4I-ugH → publicarbusquedatapped)
                Button {
                    Task {
                        await partidoVM.publicarPartido(
                            direccion: direccion,
                            posicion: posicionSeleccionada,
                            fecha: fechaSeleccionada
                        )
                        publicado = true
                        // Volver atrás después de 1 segundo (antes era dismiss implícito)
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        dismiss()
                    }
                } label: {
                    Text("Publicar")
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .cornerRadius(8)
                }
                .disabled(direccion.isEmpty || partidoVM.isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 112)
            .padding(.bottom, 40)
        }
        .navigationTitle("Buscar Faltante")
        .overlay {
            if partidoVM.isLoading {
                ProgressView()
            }
        }
    }
}
