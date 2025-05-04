// PuppyBellApp.swift
// PuppyBell

import SwiftUI

// 假数据，后续可以替换为真实用户数据
let testUser = PuppyBellUser(
    id: "test123",
    email: "test@example.com",
    displayName: "Test User",
    role: "Master", // 或 "Puppy"
    bondedUserId: "test456"
)
@main
struct PuppyBellApp: App {
    @State private var currentPage = "role" // "role", "bond", "main"
    @State private var currentUser = testUser
    var body: some Scene {
        WindowGroup {
            if currentPage == "role" {
                RoleSelectionView(currentPage: $currentPage, currentUser: $currentUser)
            }else if currentPage == "bond" {
                BondingView(currentPage: $currentPage, currentUser: $currentUser)
            }else{
                MainView(user: currentUser)
            }
            
        }
    }
}
