//
//  SceneDelegate.swift
//  Group10FinalProject
//
//  Created by kevin zhou on 11/19/24.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Check if token exists using a helper function
        let initialVC: UIViewController
        if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
            // If token exists, navigate to MainContentView
            let mainContentView = MainContentView(username: UserDefaults.standard.string(forKey: "username") ?? "User")
            initialVC = UIHostingController(rootView: mainContentView)
        } else {
            // If no token, navigate to LoginView
            let loginView = LoginView()
            initialVC = UIHostingController(rootView: loginView)
        }

        // Set up NavigationController if needed
        let navigationController = UINavigationController(rootViewController: initialVC)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.overrideUserInterfaceStyle = .light
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
}
