// RootView.swift
// Decide si mostrar Login o Home según el estado de sesión.
// Reemplaza la lógica del AppDelegate que verificaba si había usuario activo.

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                NavigationStack {
                    HomeView()
                }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        // Mientras Firebase verifica sesión mostramos un spinner
        .overlay {
            if authVM.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}
