//
//  LoginView.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = SessionManager.shared.isLoggedIn // Check login status at launch
    
    var body: some View {
        if isLoggedIn {
            MainContentView(username: SessionManager.shared.username ?? "User")
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    Text("KnowledgeKart")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 20)
                    
                    Image("appstore")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Rectangle())
                        .overlay(
                            Rectangle().stroke(Color.black, lineWidth: 2)
                        )
                        .padding(.bottom, 20)
                    Spacer()
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    Button(action: {
                        LoginController().loginUser(username: username, email: email, password: password) { success, error in
                            if success {
                                SessionManager.shared.logIn(username: username) // Save session
                                isLoggedIn = true
                            } else {
                                errorMessage = error ?? "Unknown error"
                            }
                        }
                    }) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                    
                    NavigationLink(destination: RegisterView()) {
                        Text("Don't have an account? Register here")
                            .font(.body)
                            .foregroundColor(.blue) // Standard link color
                            .underline()
                            .padding(.vertical, 10) // Add padding to increase tap area
                    }
                }
                
                .padding()
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
