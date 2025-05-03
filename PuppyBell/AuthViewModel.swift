//
//  AuthViewModel.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//


import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false

    init() {
        // 检查当前用户是否已登录
        self.isLoggedIn = Auth.auth().currentUser != nil
    }

    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    self?.isLoggedIn = true
                    completion(nil)
                }
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    self?.isLoggedIn = true
                    completion(nil)
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }
}
