// MapasView.swift
// Equivalente SwiftUI de MapasViewController.
// Reemplaza: MKMapView (UIKit) → Map de SwiftUI/MapKit.
// Skip traduce Map de SwiftUI a Google Maps en Android automáticamente.

import SwiftUI
import MapKit

struct MapasView: View {

    @EnvironmentObject var partidoVM: PartidoViewModel

    // Región inicial centrada en Buenos Aires con tipo EXPLICITO
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        // MARK: Mapa nativo (era MKMapView 7dn-Y5-Kpi, frame full screen)
        // En iOS → MapKit nativo
        // En Android via Skip → Google Maps nativo
        
        // CORRECCIÓN: Estructura explícita de inicialización compatible con Kotlin
        Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: false, userTrackingMode: nil, annotationItems: anotaciones) { (pin: PartidoPin) in
            MapAnnotation(coordinate: pin.coordinate) {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(colorParaEstado(pin.estado))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sportscourt.fill")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 16))
                    }
                    Text(pin.posicion)
                        .font(.caption2)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                }
            }
        }
        .edgesIgnoringSafeArea(Edge.Set.all) // CORRECCIÓN: Tipo completo Edge.Set.all
        .navigationTitle("Mapa de Partidos")
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline) // CORRECCIÓN: Tipo completo TitleDisplayMode.inline
    }

    // Convierte los partidos a anotaciones del mapa
    // (en la implementación completa se geocodifica la dirección)
    private var anotaciones: [PartidoPin] {
        partidoVM.partidos.enumerated().map { index, partido in
            PartidoPin(
                id: partido.id ?? UUID().uuidString,
                // Offset simulado; reemplazar con geocodificación real
                coordinate: CLLocationCoordinate2D(
                    latitude: -34.6037 + Double(index) * 0.002,
                    longitude: -58.3816 + Double(index) * 0.002
                ),
                posicion: partido.posicion,
                direccion: partido.direccion,
                estado: partido.estado
            )
        }
    }

    private func colorParaEstado(_ estado: Partido.EstadoPartido) -> Color {
        switch estado {
        case .confirmado: return Color.green
        case .pendiente:  return Color.orange
        case .cancelado:  return Color.red
        }
    }
}

// MARK: - Modelo de pin para el mapa
struct PartidoPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let posicion: String
    let direccion: String
    let estado: Partido.EstadoPartido
}
