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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
}
