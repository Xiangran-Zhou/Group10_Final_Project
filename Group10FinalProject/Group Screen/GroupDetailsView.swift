//
//  GroupDetailsView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 12/1/24.
//


import SwiftUI

struct GroupDetailsView: View {
    let group: Group

    var body: some View {
        VStack {
            Text("Group Details")
                .font(.largeTitle)
                .bold()
            Text("Group Name: \(group.name)")
                .font(.headline)
                .padding()
            Text("Group ID: \(group.id)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
        }
        .navigationBarTitle("Group Details", displayMode: .inline)
    }
}
