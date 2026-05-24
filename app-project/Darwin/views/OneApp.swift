// OneApp.swift
// Punto de entrada principal. Reemplaza AppDelegate + SceneDelegate.
// Compatible con Skip (sin UIKit).

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct OneApp: App {

    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthViewModel())
        }
    }
}
