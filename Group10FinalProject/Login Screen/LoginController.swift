//
//  LoginController.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//
import FirebaseAuth
import FirebaseFirestore

class LoginController {
    func loginUser(username: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let nsError = error as NSError
                print("Firebase Login Error: \(nsError.code), \(nsError.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("Login successful for email: \(email), username: \(username)")
                completion(true, nil)
            }
        }
    }
}
