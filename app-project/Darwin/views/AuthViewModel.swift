// AuthViewModel.swift
// Centraliza toda la lógica de autenticación Firebase.
// Reemplaza el código de FirebaseAuth disperso en LoginViewController y RecordViewController.

import SwiftUI
import SkipFirebase

import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: User?
    @Published var errorMessage: String = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Escucha cambios de sesión en tiempo real
    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isLoggedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    // MARK: - Login (era loginButtonPressed en LoginViewController)
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Registro (era registrarButtonTapped en RecordViewController)
    func register(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Recuperar contraseña (era forgotPasswordButtonPressed)
    func resetPassword(email: String) async {
        errorMessage = ""
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cerrar sesión (era logoutTapped en HomeViewController)
    func logout() {
        try? Auth.auth().signOut()
    }
}
