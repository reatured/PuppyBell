//  PuppyBellApp.swift
//  PuppyBell
//
//  Created by Lingyi Zhou on 5/3/25.
//
import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {

  func application(_ application: UIApplication,

                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    FirebaseApp.configure()

    return true

  }

}


@main
struct PuppyBellApp: App {
    @StateObject var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if authVM.isLoggedIn {
            MainView() // 你的主界面
        } else {
            AuthView()
        }
    }
}
