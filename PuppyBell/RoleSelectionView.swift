//
//  RoleSelectionView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var currentPage: String
    @Binding var currentUser: PuppyBellUser
    @State private var selectedRole: String? = nil

    var body: some View {
        VStack(spacing: 32) {
            Text("Choose Your Role")
                .font(.title)
                .padding(.top, 40)
            HStack(spacing: 40) {
                Button(action: {
                    selectedRole = "Master"
                }) {
                    VStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 40))
                            .foregroundColor(selectedRole == "Master" ? .yellow : .gray)
                        Text("Be a Master")
                            .font(.headline)
                    }
                    .padding()
                    .background(selectedRole == "Master" ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                Button(action: {
                    selectedRole = "Puppy"
                }) {
                    VStack {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 40))
                            .foregroundColor(selectedRole == "Puppy" ? .pink : .gray)
                        Text("Be a Puppy")
                            .font(.headline)
                    }
                    .padding()
                    .background(selectedRole == "Puppy" ? Color.pink.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            Button(action: {
                if let role = selectedRole {
                    currentUser.role = role
                    currentPage = "bond"
                }
            }) {
                Text("Continue")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedRole == nil ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(selectedRole == nil)
            .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
    }
}
