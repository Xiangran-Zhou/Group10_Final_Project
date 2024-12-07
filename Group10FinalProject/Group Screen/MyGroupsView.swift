//
//  MyGroupsView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 12/1/24.
//

import SwiftUI

struct MyGroupsView: View {
    @Binding var groups: [Group] // Use Binding for dynamic updates
    @State private var selectedGroupID: String = "" // Track selected group ID

    var body: some View {
        NavigationView {
            List(groups, id: \.id) { group in
                NavigationLink(
                    destination: GroupView(groupID: group.id, groupName: group.name), // Pass group's ID and name
                    label: {
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                        }
                    }
                )
            }
            .navigationTitle("My Groups")
        }
        .onAppear {
            print("Groups loaded in MyGroupsView: \(groups.map { $0.name })") // Debug
        }
    }
}

