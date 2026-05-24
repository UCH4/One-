// PartidosView.swift
// Equivalente SwiftUI de PartidosTableViewController.
// Reemplaza: UITableView + UITableViewCell "PartidoCell" + filtroSwitch (switchCambiado).

import SwiftUI

struct PartidosView: View {

    @EnvironmentObject var partidoVM: PartidoViewModel

    // era filtroSwitch (UISwitch on="YES") → switchCambiado
    @State private var filtrarPorPosicion: Bool = true

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header con switch (era el tableHeaderView con stackView)
            // era label "filtrar segun tu posicion preferente" + UISwitch Zrn-NP-rjM
            HStack {
                Text("Filtrar según tu posición preferente")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $filtrarPorPosicion)
                    .labelsHidden()
                    .onChange(of: filtrarPorPosicion) { _, nuevo in
                        // era switchCambiado IBAction
                        partidoVM.escucharPartidos(filtrarPorPosicion: nuevo)
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            Divider()

            // MARK: Lista de partidos (era UITableView estilo plain, reuseId "PartidoCell")
            if partidoVM.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if partidoVM.partidos.isEmpty {
                Spacer()
                Text("No hay partidos disponibles")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(partidoVM.partidos) { partido in
                    PartidoRowView(partido: partido, colorFondo: partidoVM.colorParaPartido(partido))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Partidos Disponibles")
        .onAppear {
            partidoVM.escucharPartidos(filtrarPorPosicion: filtrarPorPosicion)
        }
    }
}

// MARK: - Fila de partido (era UITableViewCellStyleSubtitle reuseId "PartidoCell")
// indentationLevel="5" del storyboard se representa con padding
struct PartidoRowView: View {
    let partido: Partido
    let colorFondo: Color

    private var fechaFormateada: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        fmt.locale = Locale(identifier: "es_AR")
        return fmt.string(from: partido.fecha)
    }

    var body: some View {
        HStack {
            // Indicador de color (reemplaza el fondo de celda coloreado)
            RoundedRectangle(cornerRadius: 3)
                .fill(colorFondo)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 2) {
                // textLabel (Title) — era WUB-Iq-oxf
                Text(partido.posicion)
                    .font(.body)
                    .fontWeight(.medium)

                // detailTextLabel (Subtitle) — era dXd-F5-wMq
                Text("\(partido.direccion) · \(fechaFormateada)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.leading, 4)
        }
        .padding(.vertical, 4)
        // indentationLevel="5", indentationWidth="28" del storyboard
        .padding(.leading, 5 * 4)
    }
}
