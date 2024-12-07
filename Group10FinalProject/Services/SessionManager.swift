//
//  SessionManager.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/28/24.
//

import Foundation
import FirebaseAuth
import Firebase

class SessionManager {
    static let shared = SessionManager()
    private let userDefaults = UserDefaults.standard

    private init() {}

    // MARK: - Keys
    private enum DefaultsKeys {
        static let isOfflineMode = "isOfflineMode"
        static let isLoggedIn = "isLoggedIn"
        static let username = "username"
        static let offlineGroupMembers = "offlineGroupMembers"
        static let offlineGroups = "offlineGroups"
        static let offlineFlashcardSets = "offlineFlashcardSets"
        static let offlineIndividualFlashcards = "offlineIndividualFlashcards"
    }

    // MARK: - Offline Mode
    var isOfflineMode: Bool {
        get { userDefaults.bool(forKey: DefaultsKeys.isOfflineMode) }
        set { userDefaults.set(newValue, forKey: DefaultsKeys.isOfflineMode) }
    }

    // MARK: - Login Status
    var isLoggedIn: Bool {
        userDefaults.bool(forKey: DefaultsKeys.isLoggedIn)
    }

    // MARK: - Logged-in Username
    var username: String? {
        get { userDefaults.string(forKey: DefaultsKeys.username) }
        set { userDefaults.set(newValue, forKey: DefaultsKeys.username) }
    }

    // MARK: - Offline Group Members
    var offlineGroupMembers: [GroupMember] {
        get {
            guard let data = userDefaults.data(forKey: DefaultsKeys.offlineGroupMembers) else { return [] }
            return (try? JSONDecoder().decode([GroupMember].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: DefaultsKeys.offlineGroupMembers)
            }
        }
    }

    // MARK: - Offline Groups
    var offlineGroups: [Group] {
        get {
            guard let data = userDefaults.data(forKey: DefaultsKeys.offlineGroups) else { return [] }
            return (try? JSONDecoder().decode([Group].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: DefaultsKeys.offlineGroups)
            }
        }
    }
    


    // MARK: - Offline Flashcard Sets
    var offlineFlashcardSets: [FlashcardSetModel] {
        get {
            guard let data = userDefaults.data(forKey: DefaultsKeys.offlineFlashcardSets) else { return [] }
            return (try? JSONDecoder().decode([FlashcardSetModel].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: DefaultsKeys.offlineFlashcardSets)
            }
        }
    }

    // MARK: - Offline Individual Flashcards
    var offlineIndividualFlashcards: [FlashcardModel] {
        get {
            if let data = userDefaults.data(forKey: DefaultsKeys.offlineIndividualFlashcards) {
                print("Raw saved data in UserDefaults: \(data)")
                if let decoded = try? JSONDecoder().decode([FlashcardModel].self, from: data) {
                    print("Decoded offline flashcards: \(decoded)")
                    return decoded
                }
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: DefaultsKeys.offlineIndividualFlashcards)
            }
        }
    }

    // MARK: - Individual Flashcard Handling
    func saveIndividualFlashcards(_ flashcards: [FlashcardModel]) {
            var existingFlashcards = offlineIndividualFlashcards
            existingFlashcards.append(contentsOf: flashcards)
            offlineIndividualFlashcards = existingFlashcards
            print("Saved \(flashcards.count) individual flashcards locally.")
        }

    func loadIndividualFlashcardsLocally() -> [FlashcardModel] {
        let flashcards = offlineIndividualFlashcards
        print("Loaded \(flashcards.count) offline flashcards.")
        return flashcards
    }
    func fetchAndStoreAllFlashcardsFromFirebase(completion: @escaping (Error?) -> Void) {
            let db = Firestore.firestore()
            let userID = Auth.auth().currentUser?.uid ?? "guest"
            let collectionRef = db.collection("users").document(userID).collection("flashcards")

            collectionRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching flashcards from Firebase: \(error.localizedDescription)")
                    completion(error)
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No flashcards found in Firebase.")
                    self.offlineIndividualFlashcards = [] // Clear offline flashcards if Firebase is empty
                    completion(nil)
                    return
                }

                var flashcards: [FlashcardModel] = []
                for document in documents {
                    let data = document.data()
                    if let term = data["term"] as? String, let explanation = data["explanation"] as? String {
                        flashcards.append(FlashcardModel(id: UUID().uuidString, question: term, answer: explanation))
                    }
                }

                // Save flashcards locally
                self.offlineIndividualFlashcards = flashcards
                print("Fetched and stored \(flashcards.count) flashcards locally.")
                completion(nil)
            }
        }

    // MARK: - Log In/Out
    func logIn(username: String) {
        userDefaults.set(true, forKey: DefaultsKeys.isLoggedIn)
        self.username = username
    }
    

    func logOut() {
        userDefaults.set(false, forKey: DefaultsKeys.isLoggedIn)
        userDefaults.removeObject(forKey: DefaultsKeys.username)
        userDefaults.removeObject(forKey: DefaultsKeys.offlineGroupMembers)
        userDefaults.removeObject(forKey: DefaultsKeys.offlineGroups)
        userDefaults.removeObject(forKey: DefaultsKeys.offlineFlashcardSets)
        userDefaults.removeObject(forKey: DefaultsKeys.offlineIndividualFlashcards)
    }
}
