//
//  OfflineStorage.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/28/24.
//
import CoreData
import SwiftUI

class OfflineStorage {
    static let shared = OfflineStorage()

    private let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "FlashcardStorage")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading CoreData: \(error.localizedDescription)")
            }
        }
    }

    // Save a flashcard set to Core Data
    func saveFlashcardSet(setID: String, name: String, groupID: String, flashcards: [FlashcardModel]) {
        let context = container.viewContext
        let flashcardSet = FlashcardSetEntity(context: context)
        flashcardSet.id = setID
        flashcardSet.name = name
        flashcardSet.groupID = groupID
        flashcardSet.flashcards = Set(flashcards.map { flashcard in
            let flashcardEntity = FlashcardEntity(context: context)
            flashcardEntity.id = flashcard.id
            flashcardEntity.question = flashcard.question
            flashcardEntity.answer = flashcard.answer
            return flashcardEntity
        }) as NSSet

        do {
            try context.save()
        } catch {
            print("Error saving flashcard set: \(error.localizedDescription)")
        }
    }

    // Fetch flashcard sets from Core Data
    func fetchFlashcardSets() -> [FlashcardSetModel] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<FlashcardSetEntity> = FlashcardSetEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            return results.map { setEntity in
                FlashcardSetModel(
                    id: setEntity.id ?? "",
                    name: setEntity.name ?? "",
                    groupID: setEntity.groupID ?? "",
                    flashcards: (setEntity.flashcards as? Set<FlashcardEntity>)?.compactMap { cardEntity in
                        FlashcardModel(
                            id: cardEntity.id ?? "",
                            question: cardEntity.question ?? "",
                            answer: cardEntity.answer ?? ""
                        )
                    } ?? []
                )
            }
        } catch {
            print("Error fetching flashcard sets: \(error.localizedDescription)")
            return []
        }
    }
}
