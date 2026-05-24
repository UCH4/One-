// LoginView.swift
// Equivalente SwiftUI de LoginViewController.
// Elimina: AppDelegate, SceneDelegate, IBOutlets, IBActions, Storyboard segues.

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false         // era eyeButtonPressed
    @State private var showForgotPassword: Bool = false   // era forgotPasswordButtonPressed
    @State private var navigateToRegister: Bool = false   // era segue "mostrarRegistro"

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Ícono superior (era imageView person.badge.key.fill)
            Image(systemName: "person.badge.key.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 60)
                .padding(.bottom, 80)

            // MARK: Formulario (era el stackView vertical con spacing 15)
            VStack(spacing: 15) {

                // Email (era emailTextField)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color(red: 0.949, green: 0.961, blue: 1.0))
                    .cornerRadius(8)

                // Password con ojo (era passwordTextField + eyeButton)
                ZStack(alignment: .trailing) {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color(red: 0.949, green: 0.961, blue: 0.980))
                    .cornerRadius(8)

                    // Botón ojo (era eyeButton con eye.fill)
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.gray)
                    }
                    .padding(.trailing, 16)
                }

                // Botón Log In (era loginButton)
                Button {
                    Task { await authVM.login(email: email, password: password) }
                } label: {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }

                // Botón Olvidé contraseña (era forgotPasswordButton)
                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .frame(height: 50)

                // Botón Crear cuenta (era segue "mostrarRegistro")
                Button("Create Account") {
                    navigateToRegister = true
                }
                .frame(height: 50)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8)

            Spacer()
        }
        // Error de auth
        .overlay(alignment: .bottom) {
            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundStyle(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        // Spinner (era activityIndicatorView)
        .overlay {
            if authVM.isLoading {
                ProgressView()
            }
        }
        // Sheet: Olvidé contraseña (era forgotPasswordButtonPressed → alert/vc)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet()
                .environmentObject(authVM)
        }
        // Navegación a Registro (era segue kind="presentation")
        .navigationDestination(isPresented: $navigateToRegister) {
            RegisterView()
                .environmentObject(authVM)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Sheet de recuperación de contraseña
struct ForgotPasswordSheet: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ingresá tu email para recuperar tu contraseña")
                    .multilineTextAlignment(.center)
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                if sent {
                    Text("✅ Email enviado. Revisá tu bandeja.")
                        .foregroundStyle(.green)
                }

                Button("Enviar") {
                    Task {
                        await authVM.resetPassword(email: email)
                        sent = true
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .navigationTitle("Recuperar Contraseña")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
