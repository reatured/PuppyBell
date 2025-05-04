//
//  PuppyBellUser.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//
import Foundation

struct PuppyBellUser {
    let id: String
    var email: String
    var displayName: String
    var role: String? // "Master" or "Puppy"
    var bondedUserId: String?
    var isBonded: Bool {
        bondedUserId != nil
    }
}
