//
//  BondingView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//

import SwiftUI

struct BondingView: View {
    @Binding var currentPage: String
    @Binding var currentUser: PuppyBellUser
    @State private var partnerEmail: String = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Bond with Your Partner")
                .font(.title)
                .padding(.top, 40)
            TextField("Enter partner's email", text: $partnerEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            Button(action: {
                if !partnerEmail.isEmpty {
                    // Simulate bonding by assigning a fake ID
                    currentUser.bondedUserId = "fakePartnerId"
                    currentPage = "main"
                } else {
                    showAlert = true
                }
            }) {
                Text("Bond")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(partnerEmail.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            .disabled(partnerEmail.isEmpty)
            .padding(.horizontal, 40)
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text("Please enter a valid email."), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
}
