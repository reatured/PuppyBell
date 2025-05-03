//
//  MainView.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//
import SwiftUI
struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack {
            Text("欢迎来到 PuppyBell!")
            Button("退出登录") {
                authVM.signOut()
            }
        }
    }
}
