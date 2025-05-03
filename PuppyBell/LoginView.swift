//
//  LoginView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//


import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = "richard@james.cn"
    @State private var password = "901901"
    @State private var errorMessage = ""
    @State private var isLogin = true

    var body: some View {
        VStack(spacing: 20) {
            Text(isLogin ? "登录" : "注册")
                .font(.largeTitle)
            TextField("邮箱", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
            }
            Button(isLogin ? "登录" : "注册") {
                if isLogin {
                    authVM.login(email: email, password: password) { error in
                        if let error = error {
                            errorMessage = error
                        }
                    }
                } else {
                    authVM.signUp(email: email, password: password) { error in
                        if let error = error {
                            errorMessage = error
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            Button(isLogin ? "没有账号？注册" : "已有账号？登录") {
                isLogin.toggle()
                errorMessage = ""
            }
        }
        .padding()
    }
}

