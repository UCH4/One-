// ShareView.swift
// Equivalente SwiftUI de ShareViewController.
// Optimizada estrictamente con tipado explícito para compatibilidad con Skip.

import SwiftUI

struct ShareView: View {
    @State private var seleccionPartido: String = "Partido de Prueba"
    @State private var fechaEvento: Date = Date()
    
    let partidosDisponibles = ["Partido de Prueba", "Torneo Local", "Amistoso Domingo"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Compartir Partido")
                    .font(.title)
                    .bold()
                
                campoLabel("Selecciona un encuentro")
                
                Picker("Encuentros", selection: $seleccionPartido) {
                    ForEach(partidosDisponibles, id: \.self) { partido in
                        Text(partido).tag(partido)
                    }
                }
                // CORRECCIÓN 1: Directiva para evitar errores con .wheel en Android (Skip)
                #if !SKIP
                .pickerStyle(.wheel)
                .frame(height: 150)
                #else
                .pickerStyle(.menu)
                #endif
                
                campoLabel("Fecha y Hora del Evento")
                
                // CORRECCIÓN 2: Tipado estricto y descriptores explícitos para formateadores de fecha en Kotlin
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fecha: ")
                            .bold()
                        Text(fechaEvento, style: Text.DateStyle.date)
                    }
                    
                    HStack {
                        Text("Hora: ")
                            .bold()
                        Text(fechaEvento, style: Text.DateStyle.time)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                Button(action: {
                    // Acción para compartir
                }) {
                    Text("Enviar Invitación")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Compartir")
    }
    
    @ViewBuilder
    private func campoLabel(_ texto: String) -> some View {
        Text(texto)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
