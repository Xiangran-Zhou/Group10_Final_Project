//
//  RegisterController.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//
import FirebaseAuth
import FirebaseFirestore

class RegisterController {
    func registerUser(username: String, email: String, password: String, confirmPassword: String, completion: @escaping (Bool, String?) -> Void) {
        guard password == confirmPassword else {
            completion(false, "Passwords do not match")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let nsError = error as NSError
                print("Firebase Registration Error: \(nsError.code), \(nsError.localizedDescription)")
                print("Error Domain: \(nsError.domain)")
                print("Error User Info: \(nsError.userInfo)")
                completion(false, error.localizedDescription)
            } else if let uid = authResult?.user.uid {
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData(["username": username, "email": email]) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                        completion(false, "Failed to save user data")
                    } else {
                        print("Registration successful for email: \(email), username: \(username)")
                        completion(true, nil)
                    }
                }
            }
        }
    }
}


