//
//  GroupMemberDetailView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/29/24.
//

import SwiftUI

struct GroupMemberDetailView: View {
    let member: GroupMember

    var body: some View {
        VStack(spacing: 20) {
            Text("Member Profile")
                .font(.largeTitle)
                .bold()
                .padding()

            VStack(alignment: .leading, spacing: 15) {
                Text("Name:")
                    .font(.headline)
                Text(member.name)
                    .font(.title2)

                Text("Email:")
                    .font(.headline)
                Text(member.email) // Directly display the email
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            .shadow(radius: 5)

            Spacer()
        }
        .padding()
        .navigationBarTitle("Member Profile", displayMode: .inline)
    }
}
