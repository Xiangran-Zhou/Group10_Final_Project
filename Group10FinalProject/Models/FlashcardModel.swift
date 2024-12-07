//
//  FlashcardModel.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/25/24.
//

import Foundation

// MARK: - FlashcardModel
struct FlashcardModel: Identifiable, Codable {
    var id: String
    var question: String
    var answer: String

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "question": question,
            "answer": answer
        ]
    }
}

struct FlashcardSetModel: Identifiable, Codable {
    var id: String
    var name: String
    var groupID: String // Added groupID
    var flashcards: [FlashcardModel]

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "groupID": groupID, // Include groupID
            "flashcards": flashcards.map { $0.toDictionary() }
        ]
    }
}

extension FlashcardModel {
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let question = document["question"] as? String,
              let answer = document["answer"] as? String else {
                  print("Failed to parse FlashcardModel: \(document)") // Debug
                  return nil
              }
        self.id = id
        self.question = question
        self.answer = answer
    }
}



//extension FlashcardSetModel {
//    init?(documentID: String, document: [String: Any]) {
//        guard let name = document["name"] as? String,
//              let groupID = document["groupID"] as? String,
//              let flashcardsArray = document["flashcards"] as? [[String: Any]] else { return nil }
//
//        let flashcards = flashcardsArray.compactMap { FlashcardModel(document: $0) }
//        self.id = documentID
//        self.name = name
//        self.groupID = groupID
//        self.flashcards = flashcards
//    }
//}

