//
//  MainView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//

import SwiftUI

struct MainView: View {
    var user: PuppyBellUser

    var body: some View {
        VStack(spacing: 32) {
            if user.role == "Master" {
                Text("Master Main Page")
                    .font(.title)
                Button(action: {
                    // Bell ring logic here
                }) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .padding()
                }
            } else if user.role == "Puppy" {
                Text("Puppy Main Page")
                    .font(.title)
                HStack(spacing: 24) {
                    ForEach(["Coming!", "Wait a moment", "Cuddle"], id: \.self) { response in
                        Button(response) {
                            // Respond to master
                        }
                        .padding()
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            } else {
                Text("Please select your role first.")
            }
        }
        .padding()
    }
}

