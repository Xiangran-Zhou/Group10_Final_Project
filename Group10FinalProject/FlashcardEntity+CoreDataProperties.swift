//
//  FlashcardEntity+CoreDataProperties.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/29/24.
//
//

import Foundation
import CoreData


extension FlashcardEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlashcardEntity> {
        return NSFetchRequest<FlashcardEntity>(entityName: "FlashcardEntity")
    }

    @NSManaged public var answer: String?
    @NSManaged public var id: String?
    @NSManaged public var question: String?
    @NSManaged public var parentSet: FlashcardSetEntity?

}

extension FlashcardEntity : Identifiable {

}
