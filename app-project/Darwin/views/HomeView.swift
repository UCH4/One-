// HomeView.swift
// Equivalente SwiftUI de HomeViewController.
// Reemplaza: IBOutlets MitableView, tableView, welcomeLabel, logoutButton, MyPerfilButton.
// Reemplaza: segues mostrarperfilcliente, buscarfaltante, partidos disponibles, mapa.

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var partidoVM = PartidoViewModel()

    // Navegación (reemplaza segues del storyboard)
    @State private var showPerfil: Bool = false
    @State private var showBuscarFaltante: Bool = false
    @State private var showPartidos: Bool = false
    @State private var showMapa: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Fila superior — Perfil + Mapa
            // era 2Iv-Ko-Fak (Mi Perfil) y OOA-cN-4RB (MAP)
            HStack {
                Button("Mi Perfil") { showPerfil = true }
                    .buttonStyle(.plain)
                    .frame(width: 122, height: 53)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)

                Spacer()

                Button("MAP") { showMapa = true }
                    .buttonStyle(.filled)
                    .frame(width: 60, height: 35)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // MARK: Buscar faltante (era h7b-g7-lCl → segue a ShareViewController)
            Button("Buscar Faltante") { showBuscarFaltante = true }
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 1))
                .padding(.horizontal)
                .padding(.top, 16)

            // MARK: Partidos disponibles (era HGN-PG-tKt → segue a PartidosTableViewController)
            Button("Partidos disponibles") { showPartidos = true }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)

            // MARK: Dos tablas side-by-side
            // era BV3-dK-36E (mis partidos) + 6qf-XH-YrF (todos los partidos)
            HStack(alignment: .top, spacing: 0) {

                // Tabla izquierda — Mis partidos (era BV3-dK-36E, style plain)
                VStack(alignment: .leading) {
                    Text("Mis partidos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    List(partidoVM.misPartidos) { partido in
                        PartidoCellView(partido: partido, colorFondo: partidoVM.colorParaPartido(partido))
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))

                Divider()

                // Tabla derecha — Todos los partidos (era 6qf-XH-YrF, style grouped)
                VStack(alignment: .leading) {
                    Text("Todos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    List(partidoVM.partidos) { partido in
                        PartidoCellView(partido: partido, colorFondo: partidoVM.colorParaPartido(partido))
                    }
                    .listStyle(.insetGrouped)
                    .scrollDisabled(true)
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.949, green: 0.949, blue: 0.969))
            }
            .padding(.top, 8)

            Spacer()

            // MARK: Cerrar Sesión (era logoutButton → logoutTapped)
            Button("Cerrar Sesión") {
                authVM.logout()
            }
            .frame(width: 178, height: 43)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .padding(.bottom, 16)
        }
        .navigationTitle("Bienvenido!")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            partidoVM.escucharPartidos()
            partidoVM.escucharMisPartidos()
        }
        // Navegación (reemplaza todos los segues del HomeViewController)
        .navigationDestination(isPresented: $showPerfil) {
            PerfilClienteView()
        }
        .navigationDestination(isPresented: $showBuscarFaltante) {
            ShareView()
                .environmentObject(partidoVM)
        }
        .navigationDestination(isPresented: $showPartidos) {
            PartidosView()
                .environmentObject(partidoVM)
        }
        .navigationDestination(isPresented: $showMapa) {
            MapasView()
                .environmentObject(partidoVM)
        }
    }
}

// MARK: - Celda reutilizable
// Reemplaza UITableViewCell estilo Subtitle con reuseIdentifier "PartidoCell"
struct PartidoCellView: View {
    let partido: Partido
    let colorFondo: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(partido.posicion)
                .font(.body)
            Text(partido.direccion)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .listRowBackground(colorFondo)
    }
}
