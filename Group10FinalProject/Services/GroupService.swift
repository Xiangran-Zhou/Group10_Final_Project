//
//  GroupService.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/25/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Network

class GroupService {
    private let db = Firestore.firestore()
    
    // MARK: - Group Management
    
    func createGroup(
        groupID: String,
        groupName: String,
        creatorID: String,
        creatorEmail: String,
        members: [GroupMember] = [],
        completion: @escaping (Error?) -> Void
    ) {
        if SessionManager.shared.isOfflineMode {
            // Offline mode: Save the group locally
            let newGroup = Group(id: groupID, name: groupName, members: members)
            SessionManager.shared.offlineGroups.append(newGroup)
            print("Group saved locally in offline mode: \(groupName)")
            completion(nil)
            return
        }

        // Fetch creator's username from the custom profile collection
        let userRef = Firestore.firestore().collection("users").document(creatorID)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching creator details: \(error.localizedDescription)")
                completion(error)
                return
            }

            let creatorName = document?.data()?["username"] as? String ??
                              creatorEmail.components(separatedBy: "@").first ??
                              "Unknown"

            // Save the group in Firestore
            let groupRef = Firestore.firestore().collection("groups").document(groupID)
            groupRef.setData([
                "id": groupID,
                "name": groupName,
                "createdAt": Timestamp()
            ]) { error in
                if let error = error {
                    print("Error creating group in Firestore: \(error.localizedDescription)")
                    completion(error)
                    return
                }

                print("Group \(groupName) created successfully in Firestore.")

                // Add the creator as the first member of the group
                let membersCollection = groupRef.collection("members")
                membersCollection.document(creatorID).setData([
                    "id": creatorID,
                    "name": creatorName,
                    "email": creatorEmail
                ]) { error in
                    if let error = error {
                        print("Error adding creator to group members: \(error.localizedDescription)")
                        completion(error)
                        return
                    }

                    print("Creator \(creatorName) added as a member successfully.")

                    // Add additional members if provided
                    let dispatchGroup = DispatchGroup()
                    for member in members {
                        dispatchGroup.enter()
                        membersCollection.document(member.id).setData([
                            "id": member.id,
                            "name": member.name,
                            "email": member.email
                        ]) { error in
                            if let error = error {
                                print("Error adding member \(member.name): \(error.localizedDescription)")
                            } else {
                                print("Member \(member.name) added successfully.")
                            }
                            dispatchGroup.leave()
                        }
                    }

                    // Ensure all members are added before proceeding
                    dispatchGroup.notify(queue: .main) {
                        // Initialize the "flashcards" subcollection
                        let flashcardsCollection = groupRef.collection("flashcards")
                        flashcardsCollection.document("init").setData(["initialized": true]) { error in
                            if let error = error {
                                print("Error creating flashcards subcollection: \(error.localizedDescription)")
                                completion(error)
                                return
                            }

                            print("Empty flashcards subcollection created successfully for group \(groupName).")
                            completion(nil)
                        }
                    }
                }
            }
        }
    }


    func fetchUserGroups(completion: @escaping ([Group]?, Error?) -> Void) {
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("Error: Current user email is nil.") // Debug
            completion([], nil)
            return
        }

        // Normalize the user's email to lowercase
        let normalizedUserEmail = currentUserEmail.lowercased()
        print("Normalized User Email: \(normalizedUserEmail)") // Debug

        db.collection("groups").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching groups: \(error.localizedDescription)") // Debug
                completion(nil, error)
                return
            }

            var userGroups: Set<Group> = Set() // Use Set to avoid duplicates
            let groupDocuments = snapshot?.documents ?? []
            let dispatchGroup = DispatchGroup()

            for document in groupDocuments {
                let groupID = document.documentID
                let groupName = document.data()["name"] as? String ?? "Unknown Group"

                dispatchGroup.enter()
                self.db.collection("groups").document(groupID).collection("members")
                    .whereField("email", isEqualTo: normalizedUserEmail)
                    .getDocuments { memberSnapshot, error in
                        if let error = error {
                            print("Error checking members for group \(groupID): \(error)") // Debug
                        } else if let memberSnapshot = memberSnapshot, !memberSnapshot.isEmpty {
                            print("User is a member of group: \(groupName)") // Debug
                            let group = Group(id: groupID, name: groupName, members: [])
                            userGroups.insert(group) // Add to Set (avoids duplicates)
                        } else {
                            print("User is NOT a member of group: \(groupName)") // Debug
                        }
                        dispatchGroup.leave()
                    }
            }

            dispatchGroup.notify(queue: .main) {
                print("Groups loaded: \(userGroups.map { $0.name })") // Debug
                completion(Array(userGroups), nil) // Convert Set to Array for UI compatibility
            }
        }
    }



    
    func getGroupDetails(groupID: String, completion: @escaping (GroupDetails?, [FlashcardSetModel]?, Error?) -> Void) {
        let groupRef = Firestore.firestore().collection("groups").document(groupID)

        groupRef.getDocument { document, error in
            if let error = error {
                completion(nil, nil, error)
                return
            }

            guard let document = document, document.exists,
                  let data = document.data(),
                  let groupName = data["name"] as? String else {
                completion(nil, nil, NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group details not found."]))
                return
            }

            let groupDetails = GroupDetails(id: groupID, name: groupName)

            // Fetch members
            self.fetchGroupMembers(groupID: groupID) { members, error in
                if let error = error {
                    print("Error fetching members: \(error.localizedDescription)")
                }

                // Fetch flashcards
                groupRef.collection("flashcardSets").getDocuments { snapshot, error in
                    let flashcardSets = snapshot?.documents.compactMap { doc -> FlashcardSetModel? in
                        let data = doc.data()
                        guard let name = data["name"] as? String else { return nil }
                        return FlashcardSetModel(id: doc.documentID, name: name, groupID: groupID, flashcards: [])
                    } ?? []

                    completion(groupDetails, flashcardSets, error)
                }
            }
        }
    }

    
    
    func fetchGroupMembers(groupID: String, completion: @escaping ([GroupMember]?, Error?) -> Void) {
        db.collection("groups").document(groupID).collection("members").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching members for group \(groupID): \(error)") // Debug
                completion(nil, error)
            } else {
                var members = snapshot?.documents.compactMap { doc -> GroupMember? in
                    let data = doc.data()
                    guard let name = data["name"] as? String, let email = data["email"] as? String else { return nil }
                    return GroupMember(id: doc.documentID, name: name, email: email)
                } ?? []

                // Deduplicate members by ID
                members = Array(Set(members))
                print("Unique Members for group \(groupID): \(members)") // Debug
                completion(members, nil)
            }
        }
    }

    
    // Adds a user to a group
    func joinGroup(groupID: String, userID: String, userName: String, userEmail: String, completion: @escaping (Error?) -> Void) {
        let memberRef = self.db.collection("groups").document(groupID).collection("members").whereField("email", isEqualTo: userEmail) // Add `self.` here
        memberRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error checking existing members: \(error.localizedDescription)") // Debug
                completion(error)
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                print("User \(userEmail) already exists in group \(groupID)") // Debug
                completion(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "User already exists in the group."]))
            } else {
                print("Adding user \(userName) to group \(groupID)") // Debug
                let newMemberRef = self.db.collection("groups").document(groupID).collection("members").document(userID) // Add `self.` here
                newMemberRef.setData([
                    "name": userName,
                    "email": userEmail
                ]) { error in
                    if let error = error {
                        print("Error adding user to group: \(error)") // Debug
                    } else {
                        print("User \(userName) added to group \(groupID)") // Debug
                    }
                    completion(error)
                }
            }
        }
    }

    func testFirebaseConnection() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Network is available.")
            } else {
                print("Network is unavailable. Switching to offline mode.")
                SessionManager.shared.isOfflineMode = true
            }
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    func ensureSubcollectionsExist(for groupID: String) {
        let groupRef = Firestore.firestore().collection("groups").document(groupID)

        // Ensure `flashcards` subcollection exists only if necessary
        groupRef.collection("flashcards").getDocuments { snapshot, error in
            if snapshot?.isEmpty ?? true {
                print("No flashcards found. Skipping placeholder creation.")
            }
        }

        // Ensure `members` subcollection exists only if necessary
        groupRef.collection("members").getDocuments { snapshot, error in
            if snapshot?.isEmpty ?? true {
                print("No members found. Skipping placeholder creation.")
            }
        }
    }





    
    
    // Validates if a group exists
    func validateGroupExists(groupID: String, completion: @escaping (Bool, Error?) -> Void) {
        if SessionManager.shared.isOfflineMode {
            // Check locally in offline mode
            let groupExists = SessionManager.shared.offlineGroups.contains { $0.id == groupID }
            completion(groupExists, groupExists ? nil : NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found locally"]))
        } else {
            db.collection("groups").document(groupID).getDocument { document, error in
                if let document = document, document.exists {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    // Removes a member from a group
    func removeMemberFromGroup(groupID: String, userID: String, completion: @escaping (Error?) -> Void) {
        if SessionManager.shared.isOfflineMode {
            // Remove member locally
            if let groupIndex = SessionManager.shared.offlineGroups.firstIndex(where: { $0.id == groupID }),
               let memberIndex = SessionManager.shared.offlineGroups[groupIndex].members.firstIndex(where: { $0.id == userID }) {
                SessionManager.shared.offlineGroups[groupIndex].members.remove(at: memberIndex)
                completion(nil)
            } else {
                completion(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group or member not found locally"]))
            }
        } else {
            db.collection("groups").document(groupID).collection("members").document(userID)
                .delete { error in
                    completion(error)
                }
        }
    }
    
//    // MARK: - Flashcard Management in Groups
//    // Fetch all shared flashcards for a group
//    func fetchSharedFlashcardSets(groupID: String, completion: @escaping ([FlashcardSetModel]?, Error?) -> Void) {
//        let collectionRef = db.collection("groups").document(groupID).collection("flashcardSets")
//
//        collectionRef.getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching flashcard sets: \(error.localizedDescription)")
//                completion(nil, error)
//                return
//            }
//
//            let flashcardSets = snapshot?.documents.compactMap { document -> FlashcardSetModel? in
//                let data = document.data()
//                return FlashcardSetModel(documentID: document.documentID, document: data)
//            } ?? []
//
//            print("Fetched Flashcard Sets from Firestore: \(flashcardSets)")
//            completion(flashcardSets, nil)
//        }
//    }



    // Add individual Flashcard to Group
    func addIndividualFlashcard(groupID: String, flashcard: FlashcardModel, completion: @escaping (Error?) -> Void) {
        let flashcardRef = db.collection("groups")
            .document(groupID)
            .collection("flashcards")
            .document(flashcard.id)

        if SessionManager.shared.isOfflineMode {
            // Add to offline storage
            if let groupIndex = SessionManager.shared.offlineGroups.firstIndex(where: { $0.id == groupID }) {
                let existingGroup = SessionManager.shared.offlineGroups[groupIndex]
                var flashcards = existingGroup.individualFlashcards ?? []
                flashcards.append(flashcard)
                SessionManager.shared.offlineGroups[groupIndex].individualFlashcards = flashcards
                completion(nil)
            } else {
                completion(GroupServiceError.invalidGroupID)
            }
        } else {
            flashcardRef.setData(flashcard.toDictionary()) { error in
                completion(error)
            }
        }
    }
    
    // Fetch Individual Flashcards from Group
    func fetchIndividualFlashcards(groupID: String, completion: @escaping ([FlashcardModel]?, Error?) -> Void) {
        if SessionManager.shared.isOfflineMode {
            // Fetch from offline storage
            if let group = SessionManager.shared.offlineGroups.first(where: { $0.id == groupID }) {
                completion(group.individualFlashcards, nil)
            } else {
                completion(nil, GroupServiceError.invalidGroupID)
            }
        } else {
            let flashcardRef = db.collection("groups")
                .document(groupID)
                .collection("flashcards")

            flashcardRef.getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    print("Error fetching flashcards: \(error.localizedDescription)")
                } else {
                    let flashcards = snapshot?.documents.compactMap { doc -> FlashcardModel? in
                        return FlashcardModel(document: doc.data())
                    } ?? []
                    print("Fetched Flashcards from Firestore: \(flashcards)")
                    completion(flashcards, nil)
                }
            }
        }
    }
    
    func addFlashcardSet(groupID: String, flashcardSet: FlashcardSetModel, completion: @escaping (Error?) -> Void) {
        let flashcardsData = flashcardSet.flashcards.map { flashcard in
            return flashcard.toDictionary()
        }

        if SessionManager.shared.isOfflineMode {
            // Add to local storage
            var updatedSets = SessionManager.shared.offlineFlashcardSets
            updatedSets.append(flashcardSet)
            SessionManager.shared.offlineFlashcardSets = updatedSets
            completion(nil)
        } else {
            // Add to Firestore
            db.collection("groups").document(groupID).collection("flashcardSets")
                .document(flashcardSet.id).setData([
                    "id": flashcardSet.id,
                    "name": flashcardSet.name,
                    "groupID": groupID,
                    "flashcards": flashcardsData
                ]) { error in
                    completion(error)
                }
        }
    }

    
    // Adds a flashcard set to a group
    func addFlashcardSetToGroup(groupID: String, flashcardSet: FlashcardSetModel, completion: @escaping (Error?) -> Void) {
        let flashcardsData = flashcardSet.flashcards.map { flashcard in
            return [
                "id": flashcard.id,
                "question": flashcard.question,
                "answer": flashcard.answer
            ]
        }

        if SessionManager.shared.isOfflineMode {
            // Save flashcard set locally
            var updatedSets = SessionManager.shared.offlineFlashcardSets
            updatedSets.append(flashcardSet)
            SessionManager.shared.offlineFlashcardSets = updatedSets
            completion(nil)
        } else {
            // Save to Firestore under the appropriate groupID
            db.collection("groups").document(groupID).collection("flashcardSets")
                .document(flashcardSet.id).setData([
                    "id": flashcardSet.id,
                    "name": flashcardSet.name,
                    "groupID": groupID, // Ensure groupID is saved
                    "flashcards": flashcardsData
                ]) { error in
                    completion(error)
                }
        }
    }
    
    // Fetches shared flashcard sets
    func fetchSharedFlashcardSets(groupID: String, completion: @escaping ([FlashcardSetModel]?, Error?) -> Void) {
        if SessionManager.shared.isOfflineMode {
            // Fetch flashcards from local storage in offline mode
            let localFlashcardSets = SessionManager.shared.offlineFlashcardSets.filter { $0.groupID == groupID }
            print("Offline mode: Fetched \(localFlashcardSets.count) flashcard sets for groupID: \(groupID)")
            completion(localFlashcardSets, nil)
            return
        }
        
        // Fetch flashcards from Firestore
        db.collection("groups").document(groupID).collection("flashcardSets").getDocuments { snapshot, error in
            if let error = error {
                // Log the error and pass it to the completion handler
                print("Error fetching flashcard sets from Firestore: \(error.localizedDescription)")
                completion(nil, NSError(domain: "fetchSharedFlashcardSets", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to fetch flashcard sets from Firestore. Please try again later."
                ]))
                return
            }
            
            guard let documents = snapshot?.documents else {
                // Handle case where no documents are found
                print("No flashcard sets found for groupID: \(groupID)")
                completion([], nil)
                return
            }
            
            // Parse documents into FlashcardSetModel
            let flashcardSets = documents.compactMap { document -> FlashcardSetModel? in
                guard let name = document["name"] as? String,
                      let groupID = document["groupID"] as? String,
                      let flashcardsData = document["flashcards"] as? [[String: String]] else {
                    print("Failed to parse flashcard set for documentID: \(document.documentID)")
                    return nil
                }
                
                // Parse individual flashcards
                let flashcards = flashcardsData.compactMap { data -> FlashcardModel? in
                    guard let id = data["id"], let question = data["question"], let answer = data["answer"] else {
                        print("Failed to parse flashcard data: \(data)")
                        return nil
                    }
                    return FlashcardModel(id: id, question: question, answer: answer)
                }
                
                return FlashcardSetModel(id: document.documentID, name: name, groupID: groupID, flashcards: flashcards)
            }
            
            // Merge fetched flashcards with offline flashcards
            let mergedFlashcards = self.mergeOfflineAndOnlineFlashcards(onlineSets: flashcardSets, groupID: groupID)
            
            // Update local storage with merged data
            SessionManager.shared.offlineFlashcardSets = mergedFlashcards
            print("Fetched \(mergedFlashcards.count) flashcard sets for groupID: \(groupID)")
            
            // Return the merged results
            DispatchQueue.main.async {
                completion(mergedFlashcards, nil)
            }
        }
    }
    


    private func mergeOfflineAndOnlineFlashcards(onlineSets: [FlashcardSetModel], groupID: String) -> [FlashcardSetModel] {
        var mergedSets = SessionManager.shared.offlineFlashcardSets.filter { $0.groupID != groupID }
        mergedSets.append(contentsOf: onlineSets)
        return mergedSets.uniqued(by: \.id) // Use `uniqued` to remove duplicates
    }
    
    func fetchGroupFlashcardSets(groupID: String, completion: @escaping ([FlashcardSetModel]?, Error?) -> Void) {
        guard !groupID.isEmpty else {
            completion(nil, NSError(domain: "fetchGroupFlashcardSets", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Group ID is empty. Cannot fetch flashcard sets."
            ]))
            return
        }

        let flashcardSetsRef = Firestore.firestore()
            .collection("groups")
            .document(groupID)
            .collection("flashcardSets")

        flashcardSetsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching flashcard sets: \(error.localizedDescription)")
                completion(nil, error)
            } else {
                let flashcardSets = snapshot?.documents.compactMap { doc -> FlashcardSetModel? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let flashcardsData = data["flashcards"] as? [[String: Any]] else { return nil }

                    let flashcards = flashcardsData.compactMap { flashcardData -> FlashcardModel? in
                        guard let id = flashcardData["id"] as? String,
                              let question = flashcardData["question"] as? String,
                              let answer = flashcardData["answer"] as? String else { return nil }
                        return FlashcardModel(id: id, question: question, answer: answer)
                    }

                    return FlashcardSetModel(
                        id: doc.documentID,
                        name: name,
                        groupID: groupID,
                        flashcards: flashcards
                    )
                } ?? []
                completion(flashcardSets, nil)
            }
        }
    }

    
    
    
    func shareFlashcardSet(groupID: String, flashcardSet: FlashcardSetModel, completion: @escaping (Error?) -> Void) {
        let flashcardsData = flashcardSet.flashcards.map { flashcard in
            return [
                "id": flashcard.id,
                "question": flashcard.question,
                "answer": flashcard.answer
            ]
        }

        if SessionManager.shared.isOfflineMode {
            // Save locally if in offline mode
            var updatedSets = SessionManager.shared.offlineFlashcardSets
            updatedSets.append(flashcardSet)
            SessionManager.shared.offlineFlashcardSets = updatedSets
            completion(nil)
        } else {
            // Save to Firestore
            db.collection("groups").document(groupID).collection("flashcardSets")
                .document(flashcardSet.id).setData([
                    "name": flashcardSet.name,
                    "groupID": groupID,
                    "flashcards": flashcardsData
                ]) { error in
                    completion(error)
                }
        }
    }

    // MARK: - Error Handling

        enum GroupServiceError: Error {
            case invalidGroupID
            case memberAlreadyExists
        }
    }
