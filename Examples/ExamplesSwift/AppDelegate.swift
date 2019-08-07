//
//  AppDelegate.swift
//  ExamplesSwift
//
//  Created by Victor Zhu on 2019/4/1.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

import UIKit
import AffirmSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AffirmConfiguration.shared.configure(publicKey: "2G9MNM7462PB1TAV", environment: .sandbox, merchantName: "Affirm Example Swift")
        return true
    }
}
