//
//  AppDelegate.swift
//  DiscoExample
//
//  Created by syan on 19/06/2023.
//

import UIKit
import Disco
import Network

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = .init()
        window?.makeKeyAndVisible()
        window?.rootViewController = UINavigationController(rootViewController: InterfacesVC())
        window?.backgroundColor = .black
        window?.layer.masksToBounds = true
        
        HostnameResolver.shared.start()
        NWConnection.askLocalNetworkAccess { granted in
            print("Local network access granted:", granted)
        }

        return true
    }
}

