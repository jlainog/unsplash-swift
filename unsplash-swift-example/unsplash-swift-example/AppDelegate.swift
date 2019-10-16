//
//  AppDelegate.swift
//  unsplash-swift-example
//
//  Created by jaime Laino Guerra on 9/24/19.
//  Copyright © 2019 jaime Laino Guerra. All rights reserved.
//

import UIKit
import unsplash_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Unsplash.configure(
            accessKey: "a6b5729a2ebb41bef7f72e1afdfb3601210648e8cd4c8c02c61536ab7be2d35f",
            secret: "7284c485b9bed1448134f1ecb3bd39c9cce41fe5031298fd2dc7d8cffe364bd5"
        )
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
