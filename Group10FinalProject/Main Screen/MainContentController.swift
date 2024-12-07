//
//  MainContentController.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//
import FirebaseAuth
import SwiftUI

class MainContentController: ObservableObject {
    @Published var isLoggedOut = false
    
    func logout() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully.")
            isLoggedOut = true
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

