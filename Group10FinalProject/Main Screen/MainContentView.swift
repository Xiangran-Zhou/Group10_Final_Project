//
//  MainContentView.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//

import FirebaseAuth
import SwiftUI

struct MainContentView: View {
    @State private var isLoggedOut = false
    @State private var showCreateFlashcardScreen = false
    @State private var showOfflineModeScreen = false
    @State private var showGroupModeScreen = false
    @State private var showAlert = false
    @State private var isOfflineMode = false // Shared offline mode state
    
    var username: String

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(username)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                
                Spacer()
                
                Text("Welcome to KnowledgeKart!")
                    .font(.title)
                    .bold()
                Text("This is your main content screen.")
                    .font(.subheadline)
                
                Spacer()

                // Create Flashcard Button
                Button(action: {
                    showCreateFlashcardScreen = true
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        Text("Create Flashcard")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .fullScreenCover(isPresented: $showCreateFlashcardScreen) {
                    CreateFlashcardView()
                }
                
                // Group Mode Button
                // Group Mode Button
                Button(action: {
                    if isOfflineMode {
                        showAlert = true // Show the alert
                    } else {
                        showGroupModeScreen = true // Navigate to GroupView
                    }
                }) {
                    VStack {
                        Image(systemName: "person.3.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.purple)
                        Text("Group Mode")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(isOfflineMode ? Color.gray.opacity(0.5) : Color.purple.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .alert(isPresented: $showAlert) { // Trigger alert when showAlert is true
                    Alert(
                        title: Text("Offline Mode"),
                        message: Text("You are using offline mode. Group mode is unavailable."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .fullScreenCover(isPresented: $showGroupModeScreen) {
                    GroupView()
                }


                // Offline Mode Button
                Button(action: {
                    showOfflineModeScreen = true
                }) {
                    VStack {
                        Image(systemName: "cloud")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                        Text("Offline Mode")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .fullScreenCover(isPresented: $showOfflineModeScreen) {
                    OfflineModeView(isOfflineMode: $isOfflineMode) // Pass binding
                }

                Spacer()
            }
            .navigationBarItems(
                trailing: Button(action: logOut) {
                    Text("Logout")
                        .frame(width: 80, height: 40)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            )
            .fullScreenCover(isPresented: $isLoggedOut) {
                LoginView()
            }
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut() // Firebase sign-out
            SessionManager.shared.logOut()
            isLoggedOut = true
        } catch let error {
            print("Failed to log out: \(error.localizedDescription)")
        }
    }
}
