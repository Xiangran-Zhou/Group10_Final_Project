//
//  GroupModel.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/25/24.
//

import Foundation

struct Group: Codable, Identifiable {
    var id: String
    var name: String
    var members: [GroupMember]
    var individualFlashcards: [FlashcardModel]?

    init(id: String, name: String, members: [GroupMember], individualFlashcards: [FlashcardModel]? = nil) {
        self.id = id
        self.name = name
        self.members = members
        self.individualFlashcards = individualFlashcards
    }
}


struct GroupMember: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String

    static func == (lhs: GroupMember, rhs: GroupMember) -> Bool {
        return lhs.id == rhs.id
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct GroupDetails {
    let id: String
    let name: String
}

extension Group: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use `id` as the unique identifier
    }

    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }
}
