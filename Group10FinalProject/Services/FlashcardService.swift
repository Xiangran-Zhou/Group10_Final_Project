//
//  FlashcardService.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/29/24.
//

import Foundation
import Firebase

class FlashcardService {
    static let shared = FlashcardService()

    private let db = Firestore.firestore()

    // Fetch flashcard sets from Firebase
    func fetchFlashcardSets(for username: String, completion: @escaping ([FlashcardSetModel]?, Error?) -> Void) {
        db.collection("flashcards").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }

            let flashcardSets = snapshot?.documents.compactMap { document -> FlashcardSetModel? in
                try? document.data(as: FlashcardSetModel.self)
            }
            completion(flashcardSets, nil)
        }
    }

    // Save a new flashcard set to Firebase
    func saveFlashcardSet(_ set: FlashcardSetModel, for username: String, completion: @escaping (Error?) -> Void) {
        var newSet = set
        newSet.name = username
        db.collection("flashcards").document(set.id).setData(newSet.toDictionary()) { error in
            completion(error)
        }
    }
}
