//
//  OfflineModeView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/25/24.
//

import SwiftUI

struct OfflineModeView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isOfflineMode: Bool // Use a binding to update the parent view's state
    @State private var flashcards: [FlashcardModel] = []
    @State private var flashcardSets: [FlashcardSetModel] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Offline Mode Information
                if isOfflineMode {
                    VStack(alignment: .center, spacing: 10) {
                        Text("You are not connected to the Internet right now.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Text("You can review the flashcards stored on your device.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
                
                // Toggle for Offline/Online Mode
                Toggle(isOn: $isOfflineMode) {
                    Text(isOfflineMode ? "Offline Mode" : "Online Mode")
                        .font(.headline)
                        .foregroundColor(isOfflineMode ? .green : .gray)
                }
                .onChange(of: isOfflineMode) { newValue in
                    SessionManager.shared.isOfflineMode = newValue
                    if newValue {
                        loadFlashcards() // Load flashcards when offline mode is toggled
                    } else {
                        flashcards = [] // Clear data when switching to online mode
                    }
                }
                .padding()
                
                Spacer()
                
                // Display Individual Flashcards in Offline Mode
                if isOfflineMode {
                    if flashcards.isEmpty {
                        Text("No flashcards available.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        List(flashcards) { card in
                            VStack(alignment: .leading) {
                                Text("Term: \(card.question)")
                                    .font(.headline)
                                Text("Explanation: \(card.answer)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } else {
                    Text("You are in online mode.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Offline Mode")
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            )
            .onAppear {
                if isOfflineMode {
                    loadFlashcards()
                    print("Offline flashcards loaded successfully.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadFlashcards() {
        if isOfflineMode {
            SessionManager.shared.fetchAndStoreAllFlashcardsFromFirebase { error in
                if let error = error {
                    print("Error fetching flashcards from Firebase: \(error.localizedDescription)")
                } else {
                    self.flashcards = SessionManager.shared.loadIndividualFlashcardsLocally()
                    print("Loaded flashcards from Firebase for offline mode: \(self.flashcards.count)")
                }
            }
        } else {
            flashcards = []
            print("Cleared offline flashcards as offline mode is disabled.")
        }
    }


}
