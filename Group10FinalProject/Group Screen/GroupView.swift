//
//  GroupView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/25/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GroupView: View {
    @State private var groupID: String // Use as an initial value passed from MyGroupsView
    @State private var groupName : String // Empty initially
    @State private var members: [GroupMember] = [] // Group Members
    @State private var flashcardSets: [FlashcardSetModel] = [] // Flashcard Sets
    @State private var isOfflineMode = false // Offline Mode Indicator
    @State private var showErrorAlert = false // Error Alert Toggle
    @State private var errorMessage = "" // Error Message
    @State private var currentSheet: SheetType? // Current Sheet Type
    @State private var isLoading: Bool = false // Loading indicator for fetch operations
    @State private var individualFlashcards: [FlashcardModel] = [] // Individual flashcards
    @State private var selectedFlashcards: [FlashcardModel] = [] // Flashcards selected to create a set
    @State private var newSetName: String = "" // Name for the new flashcard set
    @State private var myGroups: [Group] = [] // List of groups the user is part of
    @State private var showMyGroupsView = false // Toggle for navigating to "My Groups"
    @State private var username: String = "" // Local state for username
    @State private var email: String = "" // Local state for email
    @State private var userFlashcards: [FlashcardModel] = [] // User's personal flashcards

    
    init(groupID: String = "", groupName: String = "") { // Default values
            _groupID = State(initialValue: groupID)
            _groupName = State(initialValue: groupName)
        }

    enum SheetType: Identifiable {
        case createGroup
        case joinGroup
        case addMember
        case shareFlashcard

        var id: Int { hashValue }
    }

    @Environment(\.presentationMode) var presentationMode // For Back Navigation
    private let groupService = GroupService() // Service Layer for Group-Related API Calls

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    Text("Group Dashboard")
                        .font(.largeTitle)
                        .bold()

                    if groupID.isEmpty {
                        // No Group ID: Show options for creating or joining a group
                        noGroupView()
                    } else {
                        // Group Info and Actions
                        groupInfoSection()
                        actionButtons()
                        groupMembersSection()
                        groupFlashcardsSection()
                    }
                }
                // Loading Indicator Overlay
                if isLoading {
                    loadingOverlay()
                }
            }
            .navigationBarTitle("Group Dashboard", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            )
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(item: $currentSheet) { sheet in
                switch sheet {
                case .createGroup:
                    createGroupSheet()
                case .joinGroup:
                    joinGroupSheet()
                case .addMember:
                    addMemberSheet()
                case .shareFlashcard:
                    shareFlashcardSheet()
                }
            }
            .onAppear {
                onAppearLogic()
            }
        }
    }
    private func fetchMyGroups() {
        groupService.fetchUserGroups { groups, error in
            DispatchQueue.main.async {
                if let groups = groups {
                    print("Fetched groups: \(groups.map { $0.name })") // Debug
                    self.myGroups = groups
                    self.showMyGroupsView = true // Show MyGroupsView only after groups are updated
                } else if let error = error {
                    print("Error fetching groups: \(error.localizedDescription)") // Debug
                    self.errorMessage = "Error fetching groups: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }



    struct GroupDetailsView: View {
        let group: Group

        var body: some View {
            Text("Details for Group: \(group.name)")
                .font(.title)
                .padding()
        }
    }


    // MARK: - UI Components
    private func noGroupView() -> some View {
        VStack(spacing: 20) {
            Text("You are not part of any group yet.")
                .foregroundColor(.gray)
                .font(.body)

            Text("Would you like to create a new group or join an existing group?")
                .foregroundColor(.gray)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { currentSheet = .createGroup }) {
                Text("Create a New Group")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            Button(action: { fetchMyGroups() }) {
                Text("My Groups")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .sheet(isPresented: $showMyGroupsView) {
                MyGroupsView(groups: $myGroups)
            }

            Button(action: { currentSheet = .joinGroup }) {
                Text("Join an Existing Group")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
        .padding()
    }


    private func groupInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Group Name: \(groupName)")
                .font(.headline)

            Button(action: { currentSheet = .createGroup }) {
                Text("Create new Group")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }

    private func actionButtons() -> some View {
        HStack(spacing: 15) {
            Button(action: { currentSheet = .addMember }) {
                Text("Add Member")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                fetchFlashcardSets()
                fetchUserFlashcards()
                currentSheet = .shareFlashcard
            }) {
                Text("Share Flashcard Set")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.purple.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

    private func groupMembersSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Group Members:")
                .font(.headline)

            if members.isEmpty {
                Text("No members found.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                List {
                    ForEach(members, id: \.id) { member in
                        NavigationLink(
                            destination: GroupMemberDetailView(member: member)
                        ) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.headline)
                                    Text(member.email.isEmpty ? "Email not available": member.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: {
                                    removeMember(member)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle()) // Prevents interference with NavigationLink
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    


    
    private func sharedFlashcardsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Flashcard Set or Individual Flashcards")
                .font(.title)
                .bold()
                .padding()

            if flashcardSets.isEmpty && individualFlashcards.isEmpty {
                Text("No flashcards available to share.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Display Flashcard Sets
                        if !flashcardSets.isEmpty {
                            Text("Flashcard Sets:")
                                .font(.headline)
                            ForEach(flashcardSets) { set in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(set.name)
                                        .font(.headline)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)

                                    ForEach(set.flashcards) { flashcard in
                                        VStack(alignment: .leading) {
                                            Text("Q: \(flashcard.question)")
                                                .font(.subheadline)
                                            Text("A: \(flashcard.answer)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        // Display Individual Flashcards
                        if !individualFlashcards.isEmpty {
                            Text("Individual Flashcards:")
                                .font(.headline)
                            ForEach(individualFlashcards) { flashcard in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(flashcard.question)
                                            .font(.headline)
                                        Text(flashcard.answer)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        toggleFlashcardSelection(flashcard)
                                    }) {
                                        Image(systemName: selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? .blue : .gray)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
        }
    }


    private func loadingOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView("Loading...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }


    // MARK: - Sheet Content Views
    private func createGroupSheet() -> some View {
        VStack {
            Text("Create New Group")
                .font(.title)
                .bold()
            TextField("Enter Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Create Group") {
                createNewGroup()
                currentSheet = nil
            }
            .disabled(groupName.isEmpty)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
        .padding()
    }

    private func joinGroupSheet() -> some View {
        VStack {
            Text("Join Existing Group")
                .font(.title)
                .bold()
            TextField("Enter Group Name", text: $groupName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Join") {
                joinGroup()
                currentSheet = nil
            }
        }
        .padding()
    }

    
    private func groupFlashcardsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Group Flashcards:")
                .font(.headline)

            if individualFlashcards.isEmpty {
                Text("No group flashcards available.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(individualFlashcards) { flashcard in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Q: \(flashcard.question)")
                                    .font(.subheadline)
                                Text("A: \(flashcard.answer)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }

    

    private func addMemberSheet() -> some View {

        return VStack(spacing: 20) {
            Text("Add New Member")
                .font(.largeTitle)
                .bold()
                .padding()

            VStack(alignment: .leading, spacing: 15) {
                Text("Username")
                    .font(.headline)
                TextField("Enter Username", text: $username) // Bind to local state
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Text("Email")
                    .font(.headline)
                TextField("Enter Email", text: $email) // Bind to local state
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress) // Email-specific keyboard
            }

            Button("Add Member") {
                addNewMember(name: username, email: email) // Pass local state
                currentSheet = nil
            }
            .disabled(username.isEmpty || email.isEmpty) // Disable button if fields are empty
            .frame(maxWidth: .infinity, minHeight: 50)
            .background((username.isEmpty || email.isEmpty) ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
        .padding()
    }




    private func shareFlashcardSheet() -> some View {
        NavigationView {
            VStack {
                Text("Select Flashcard Set or Individual Flashcards")
                    .font(.title)
                    .bold()
                    .padding()

                if userFlashcards.isEmpty {
                    Text("No personal flashcards available to share.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // Display User Flashcards
                            Text("Your Flashcards:")
                                .font(.headline)
                            ForEach(userFlashcards) { flashcard in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Q: \(flashcard.question)")
                                            .font(.headline)
                                        Text("A: \(flashcard.answer)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        toggleFlashcardSelection(flashcard)
                                    }) {
                                        Image(systemName: selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? .blue : .gray)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }

                // Add to Group Button
                Button(action: {
                    isLoading = true // Show loading indicator
                        var successfullyAdded = 0
                        let totalToAdd = selectedFlashcards.count
                        
                        for flashcard in selectedFlashcards {
                            groupService.addIndividualFlashcard(groupID: groupID, flashcard: flashcard) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.showErrorAlert = true
                                } else {
                                    successfullyAdded += 1
                                    print("Flashcard \(flashcard.question) added to group.")
                                    if successfullyAdded == totalToAdd {
                                        // All flashcards have been added, fetch updated data
                                        fetchGroupFlashcards(groupID: groupID) { flashcards, error in
                                            isLoading = false // Hide loading indicator
                                            if let flashcards = flashcards {
                                                self.individualFlashcards = flashcards
                                            } else if let error = error {
                                                self.errorMessage = error.localizedDescription
                                                self.showErrorAlert = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        currentSheet = nil
                }) {
                    Text("Add to Group")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
                .disabled(selectedFlashcards.isEmpty)
            }
            .navigationBarItems(
                leading: Button(action: {
                    currentSheet = nil // Close the sheet
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            )
            .padding()
        }
    }




    
    private func individualFlashcardsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Individual Flashcards:")
                .font(.headline)

            if individualFlashcards.isEmpty {
                Text("No individual flashcards available.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                List {
                    ForEach(individualFlashcards) { flashcard in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(flashcard.question)
                                    .font(.headline)
                                Text(flashcard.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                toggleFlashcardSelection(flashcard)
                            }) {
                                Image(systemName: selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedFlashcards.contains(where: { $0.id == flashcard.id }) ? .blue : .gray)
                            }
                        }
                    }
                }
            }

            if !selectedFlashcards.isEmpty {
                TextField("Enter a name for the new flashcard set", text: $newSetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: createFlashcardSet) {
                    Text("Create Flashcard Set")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(newSetName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                }
                .disabled(newSetName.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .shadow(radius: 5)
    }


    // MARK: - Lifecycle and Logic
    private func onAppearLogic() {
        if isOfflineMode {
            // Load data from local storage in offline mode
            members = loadGroupMembersLocally()
            flashcardSets = loadFlashcardSetsLocally()
            individualFlashcards = loadIndividualFlashcardsLocally()
            print("Flashcard Sets (Offline): \(flashcardSets)")
            print("Individual Flashcards (Offline): \(individualFlashcards)")
        } else {
            // Fetch group details if groupID is provided
            if !groupID.isEmpty {
                print("Fetching group details for groupID: \(groupID)")

                fetchGroupMembers(groupID: groupID) { members, error in
                    if let error = error {
                        print("Error fetching members: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                    } else {
                        print("Fetched Members: \(members ?? [])")
                        self.members = members ?? []
                    }
                }
                fetchGroupFlashcards(groupID: groupID) { flashcards, error in
                            if let flashcards = flashcards {
                                self.individualFlashcards = flashcards
                            } else if let error = error {
                                self.errorMessage = error.localizedDescription
                                self.showErrorAlert = true
                            }
                        }
                fetchUserFlashcards()
//                fetchFlashcardSets() // Fetch flashcard sets for the group
//               fetchFlashcards()    // Fetch individual flashcards for the group
            } else {
                print("Group ID is empty, unable to fetch group details.")
            }
        }

        testFirebaseConnection() // Test Firebase connection
        monitorNetwork()         // Monitor network status
    }


    private func testFirebaseConnection() {
        Firestore.firestore().collection("test").getDocuments { snapshot, error in
            if let error = error {
                print("Error connecting to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully connected to Firestore.")
            }
        }
    }
    
    private func validateGroupExistsBeforeFetch() {
        guard !groupID.isEmpty else {
            self.errorMessage = "Group ID is empty. Please join or create a group."
            self.showErrorAlert = true
            return
        }

        groupService.validateGroupExists(groupID: groupID) { exists, error in
            if !exists {
                self.errorMessage = "Group does not exist. Please check the Group ID."
                self.showErrorAlert = true
            } else {
                print("Group exists. Proceeding with fetch operations.") // Debug log
            }
        }
    }
    
    private func fetchFlashcards() {
        self.isLoading = true

        Firestore.firestore().collection("flashcards").getDocuments { snapshot, error in
            self.isLoading = false
            if let error = error {
                print("Error fetching flashcards: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else if let documents = snapshot?.documents {
                self.individualFlashcards = documents.compactMap { doc -> FlashcardModel? in
                    let data = doc.data()
                    guard let term = data["term"] as? String,
                          let explanation = data["explanation"] as? String else { return nil }
                    return FlashcardModel(id: doc.documentID, question: term, answer: explanation)
                }
                print("Fetched Flashcards: \(self.individualFlashcards)")
            }
        }
    }
    
    func fetchGroupFlashcards(groupID: String, completion: @escaping ([FlashcardModel]?, Error?) -> Void) {
        guard !groupID.isEmpty else {
            completion(nil, NSError(domain: "fetchGroupFlashcards", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Group ID is empty. Cannot fetch flashcards."
            ]))
            return
        }

        let groupFlashcardsRef = Firestore.firestore()
            .collection("groups")
            .document(groupID)
            .collection("flashcards")

        groupFlashcardsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching group flashcards: \(error.localizedDescription)")
                completion(nil, error)
            } else {
                let flashcards = snapshot?.documents.compactMap { doc -> FlashcardModel? in
                    let data = doc.data()
                    guard let question = data["question"] as? String,
                          let answer = data["answer"] as? String else { return nil }
                    return FlashcardModel(id: doc.documentID, question: question, answer: answer)
                } ?? []
                completion(flashcards, nil)
            }
        }
    }


    private func fetchFlashcardSets() {
        guard !groupID.isEmpty else {
            self.errorMessage = "Group ID cannot be empty."
            self.showErrorAlert = true
            return
        }

        self.isLoading = true

        Firestore.firestore().collection("groups").document(groupID).collection("flashcardSets").getDocuments { snapshot, error in
            self.isLoading = false
            if let error = error {
                print("Error fetching flashcard sets: \(error.localizedDescription)")
                self.errorMessage = "Could not fetch flashcards online. Loading offline data..."
                self.showErrorAlert = true
                loadFlashcardsFromOffline() // Fallback to offline mode
            } else if let documents = snapshot?.documents {
                self.flashcardSets = documents.compactMap { doc -> FlashcardSetModel? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let flashcardsData = data["flashcards"] as? [[String: Any]] else { return nil }

                    let flashcards = flashcardsData.compactMap { flashcardData -> FlashcardModel? in
                        guard let id = flashcardData["id"] as? String,
                              let question = flashcardData["question"] as? String,
                              let answer = flashcardData["answer"] as? String else { return nil }
                        return FlashcardModel(id: id, question: question, answer: answer)
                    }

                    return FlashcardSetModel(id: doc.documentID, name: name, groupID: self.groupID, flashcards: flashcards)
                }

                // Save retrieved flashcards to offline storage
                saveFlashcardsToOffline()
            }
        }
    }
    private func saveFlashcardsToOffline() {
        for set in flashcardSets {
            OfflineStorage.shared.saveFlashcardSet(
                setID: set.id,
                name: set.name,
                groupID: set.groupID,
                flashcards: set.flashcards
            )
        }
        print("Flashcards saved to offline storage.")
    }

    
    private func loadFlashcardsFromOffline() {
        self.flashcardSets = OfflineStorage.shared.fetchFlashcardSets()
        print("Loaded flashcards from offline storage: \(flashcardSets.count)")
    }






    func fetchGroupMembers(groupID: String, completion: @escaping ([GroupMember]?, Error?) -> Void) {
        if SessionManager.shared.isOfflineMode {
            // Offline mode: Fetch members locally
            if let group = SessionManager.shared.offlineGroups.first(where: { $0.id == groupID }) {
                completion(group.members, nil)
            } else {
                completion([], nil)
            }
        } else {
            // Online mode: Fetch members from Firestore
            Firestore.firestore().collection("groups").document(groupID).collection("members").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching members for group \(groupID): \(error)") // Debug
                    completion(nil, error)
                } else {
                    let members = snapshot?.documents.compactMap { doc -> GroupMember? in
                        let data = doc.data()
                        guard let name = data["name"] as? String, let email = data["email"] as? String else { return nil }
                        return GroupMember(id: doc.documentID, name: name, email: email)
                    } ?? []
                    DispatchQueue.main.async {
                        completion(members, nil)
                    }
                }
            }
        }
    }




    private func createNewGroup() {
        guard !groupName.isEmpty else {
            self.errorMessage = "Please enter a valid Group Name."
            self.showErrorAlert = true
            return
        }

        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User is not logged in. Please log in to create a group."
            self.showErrorAlert = true
            return
        }

        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            self.errorMessage = "Unable to fetch user email. Please try again."
            self.showErrorAlert = true
            return
        }

        let newGroupID = UUID().uuidString

        groupService.createGroup(
            groupID: newGroupID,
            groupName: groupName,
            creatorID: currentUserID,
            creatorEmail: currentUserEmail
        ) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else {
                print("Group created successfully.")
                // Update UI with new group details
                self.groupID = newGroupID
                self.groupName = groupName

                // Fetch user flashcards immediately after group creation
                self.fetchUserFlashcards()

                // Fetch group members to update UI
                self.fetchGroupMembers(groupID: newGroupID) { members, error in
                    if let members = members {
                        self.members = members
                    } else if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                    }
                }
            }
        }
    }


    private func joinGroup() {
        guard !groupName.isEmpty else {
            self.errorMessage = "Please enter a valid Group Name."
            self.showErrorAlert = true
            return
        }

        // Search Firestore for the group by name
        let groupRef = Firestore.firestore().collection("groups")
        groupRef.whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Error searching for group: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                self.errorMessage = "No group found with the name \(self.groupName). Please check the name and try again."
                self.showErrorAlert = true
                return
            }

            if documents.count > 1 {
                // Handle duplicate group names
                self.errorMessage = "Multiple groups found with the name \(self.groupName). Please select the correct group."
                self.showErrorAlert = true
                return
            }

            // Get the group document and its ID
            guard let document = documents.first else { return }
            let groupID = document.documentID

            // Add the user to the group
            self.addUserToGroup(groupID: groupID) { success in
                if success {
                    self.groupID = groupID // Set groupID after a successful join
                    self.fetchGroupDetailsAndFlashcards(groupID: groupID)
                    self.groupService.fetchUserGroups { groups, error in
                        if let groups = groups {
                            self.myGroups = groups
                        } else if let error = error {
                            print("Error refreshing user groups: \(error.localizedDescription)")
                        }
                    }

                } else {
                    self.errorMessage = "Failed to join group. Please try again later."
                    self.showErrorAlert = true
                }
            }
        }
    }


    private func addUserToGroup(groupID: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User is not logged in. Please log in to join a group."
            self.showErrorAlert = true
            completion(false)
            return
        }

        let usersCollection = Firestore.firestore().collection("users")
        usersCollection.document(currentUserID).getDocument { document, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                completion(false)
                return
            }

            guard let document = document, document.exists else {
                self.errorMessage = "User document does not exist in Firestore."
                self.showErrorAlert = true
                completion(false)
                return
            }

            let userData = document.data()
            guard let userName = userData?["username"] as? String,
                  let userEmail = userData?["email"] as? String else {
                self.errorMessage = "Missing user details in Firestore."
                self.showErrorAlert = true
                completion(false)
                return
            }

            let memberRef = Firestore.firestore()
                .collection("groups")
                .document(groupID)
                .collection("members")
                .document(currentUserID)

            memberRef.setData([
                "id": currentUserID,
                "name": userName,
                "email": userEmail
            ]) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    completion(false)
                    return
                }

                print("User \(userName) successfully added to group \(groupID).")

                // Ensure the flashcards subcollection exists
                let flashcardsRef = Firestore.firestore()
                    .collection("groups")
                    .document(groupID)
                    .collection("flashcards")

                flashcardsRef.getDocuments { snapshot, error in
                    if snapshot?.isEmpty ?? true {
                        // Create an empty flashcards subcollection
                        flashcardsRef.document("init").setData(["initialized": true]) { error in
                            completion(error == nil)
                        }
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }



    private func fetchGroupDetailsAndFlashcards(groupID: String) {
        groupService.getGroupDetails(groupID: groupID) { details, flashcardSets, error in
            if let error = error {
                self.errorMessage = "Error fetching group details: \(error.localizedDescription)"
                self.showErrorAlert = true
                return
            }

            if let details = details {
                self.groupID = details.id
                self.groupName = details.name
            } else {
                self.errorMessage = "Group details could not be loaded."
                self.showErrorAlert = true
            }

            // Fetch and update members
            self.fetchGroupMembers(groupID: groupID) { members, error in
                if let members = members {
                    self.members = members
                } else if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }

            // Fetch and update flashcards
            self.fetchGroupFlashcards(groupID: groupID) { flashcards, error in
                if let flashcards = flashcards {
                    self.individualFlashcards = flashcards
                } else if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }

            // Fetch flashcard sets
            self.fetchFlashcardSets()
        }
    }







    private func addNewMember(name: String, email: String) {
        guard !name.isEmpty, !email.isEmpty else {
            self.errorMessage = "Both name and email are required to add a member."
            self.showErrorAlert = true
            return
        }

        let newMember = GroupMember(id: UUID().uuidString, name: name, email: email)

        if isOfflineMode {
            // Offline mode: Add the member locally
            self.members.append(newMember)
            SessionManager.shared.offlineGroupMembers = self.members
        } else {
            // Online mode: Add member to Firestore
            groupService.joinGroup(groupID: self.groupID, userID: newMember.id, userName: name, userEmail: email) { error in
                if let error = error {
                    self.errorMessage = "Failed to add member: \(error.localizedDescription)"
                    self.showErrorAlert = true
                } else {
                    DispatchQueue.main.async {
                        self.members.append(newMember) // Update UI
                    }
                }
            }
        }
    }


    private func removeMember(_ member: GroupMember) {
        if isOfflineMode {
            // Remove locally
            members.removeAll { $0.id == member.id }
            SessionManager.shared.offlineGroupMembers = members
        } else {
            // Remove from Firestore
            groupService.removeMemberFromGroup(groupID: groupID, userID: member.id) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                } else {
                    members.removeAll { $0.id == member.id }
                }
            }
        }
    }

    
    private func shareFlashcardSet(_ set: FlashcardSetModel) {
        if isOfflineMode {
            var sharedSets = SessionManager.shared.offlineFlashcardSets
            sharedSets.append(set)
            SessionManager.shared.offlineFlashcardSets = sharedSets
        } else {
            groupService.shareFlashcardSet(groupID: groupID, flashcardSet: set) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func createFlashcardSetFromSelected(_ selectedFlashcards: [FlashcardModel], setName: String) {
        guard !setName.isEmpty else {
            self.errorMessage = "Set name cannot be empty."
            self.showErrorAlert = true
            return
        }

        let newSet = FlashcardSetModel(
            id: UUID().uuidString,
            name: setName,
            groupID: groupID,
            flashcards: selectedFlashcards
        )

        groupService.addFlashcardSet(groupID: groupID, flashcardSet: newSet) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else {
                self.flashcardSets.append(newSet)
            }
        }
    }
    
    private func fetchUserFlashcards() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User is not logged in. Cannot fetch personal flashcards."
            self.showErrorAlert = true
            return
        }

        print("Fetching flashcards for userID: \(currentUserID)")

        let userFlashcardsRef = Firestore.firestore()
            .collection("users")
            .document(currentUserID)
            .collection("flashcards")

        userFlashcardsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user flashcards: \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch personal flashcards. Try again later."
                self.showErrorAlert = true
            } else if let snapshot = snapshot {
                self.userFlashcards = snapshot.documents.compactMap { doc -> FlashcardModel? in
                    let data = doc.data()
                    guard let term = data["term"] as? String,
                          let explanation = data["explanation"] as? String else {
                        print("Invalid flashcard data: \(data)")
                        return nil
                    }
                    return FlashcardModel(id: doc.documentID, question: term, answer: explanation)
                }

                print("Fetched User Flashcards: \(self.userFlashcards.map { $0.question })")
            }
        }
    }


    
    // Toggle flashcard selection
    private func toggleFlashcardSelection(_ flashcard: FlashcardModel) {
        if let index = selectedFlashcards.firstIndex(where: { $0.id == flashcard.id }) {
            selectedFlashcards.remove(at: index)
            print("Deselected Flashcard: \(flashcard.question)")
        } else {
            selectedFlashcards.append(flashcard)
            print("Selected Flashcard: \(flashcard.question)")
        }
        print("Currently Selected Flashcards: \(selectedFlashcards.map { $0.question })")
    }


    // Create a flashcard set from selected flashcards
    private func createFlashcardSet() {
        guard !newSetName.isEmpty else { return }
        let newSetID = UUID().uuidString
        let newFlashcardSet = FlashcardSetModel(id: newSetID, name: newSetName, groupID: groupID, flashcards: selectedFlashcards)

        groupService.addFlashcardSetToGroup(groupID: groupID, flashcardSet: newFlashcardSet) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else {
                self.flashcardSets.append(newFlashcardSet) // Update UI
                self.selectedFlashcards.removeAll() // Clear selection
                self.newSetName = "" // Clear input
            }
        }
    }



    // MARK: - Offline Data Handling
    private func loadGroupMembersLocally() -> [GroupMember] {
        return SessionManager.shared.offlineGroups.first(where: { $0.id == groupID })?.members ?? []
    }

    private func loadFlashcardSetsLocally() -> [FlashcardSetModel] {
        print("Offline Flashcard Sets: \(SessionManager.shared.offlineFlashcardSets)")
        return SessionManager.shared.offlineFlashcardSets
    }


    private func loadIndividualFlashcardsLocally() -> [FlashcardModel] {
        let flashcards = SessionManager.shared.offlineGroups
            .first(where: { $0.id == groupID })?.individualFlashcards ?? []
        print("Individual Flashcards from Local: \(flashcards)")
        return flashcards
    }

    private func saveGroupMembersLocally(members: [GroupMember]) {
        if var group = SessionManager.shared.offlineGroups.first(where: { $0.id == groupID }) {
            group.members = members
        } else {
            let newGroup = Group(id: groupID, name: groupName, members: members)
            SessionManager.shared.offlineGroups.append(newGroup)
        }
    }

    private func saveFlashcardSetsLocally(sets: [FlashcardSetModel]) {
        SessionManager.shared.offlineFlashcardSets = sets
    }
}

extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return self.filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}

import Network // Import required for NWPathMonitor

private func monitorNetwork() {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in
        if path.status == .satisfied {
            print("Network is available.")
        } else {
            print("Network is unavailable.")
        }
    }
    let queue = DispatchQueue.global(qos: .background)
    monitor.start(queue: queue)
}
