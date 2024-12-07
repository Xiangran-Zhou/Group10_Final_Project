//
//  FlashcardSetEntity+CoreDataProperties.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/29/24.
//
//

import Foundation
import CoreData


extension FlashcardSetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlashcardSetEntity> {
        return NSFetchRequest<FlashcardSetEntity>(entityName: "FlashcardSetEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var groupID: String?
    @NSManaged public var flashcards: NSSet?

}

// MARK: Generated accessors for flashcards
extension FlashcardSetEntity {

    @objc(addFlashcardsObject:)
    @NSManaged public func addToFlashcards(_ value: FlashcardEntity)

    @objc(removeFlashcardsObject:)
    @NSManaged public func removeFromFlashcards(_ value: FlashcardEntity)

    @objc(addFlashcards:)
    @NSManaged public func addToFlashcards(_ values: NSSet)

    @objc(removeFlashcards:)
    @NSManaged public func removeFromFlashcards(_ values: NSSet)

}

extension FlashcardSetEntity : Identifiable {

}
