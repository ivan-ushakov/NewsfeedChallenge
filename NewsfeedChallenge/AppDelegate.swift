//
//  AppDelegate.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

import VK_ios_sdk

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var authService: AuthServiceType?
    
    private var webService: WebServiceType?

    private var router: Router?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.authService = AuthService()
        self.router = Router()
        
        self.authService?.auth(success: { [weak self] token in
            self?.start(WebService(token: token))
        }) { [weak self] error in
            self?.router?.showError(error)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {

    }

    func applicationWillTerminate(_ application: UIApplication) {

    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.authService?.processOpen(url: url, options: options)
        
        return true
    }
    
    private func start(_ webService: WebServiceType) {
        self.webService = webService
        self.router?.showNewsfeed(webService: webService)
    }
}
