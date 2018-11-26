//
//  Router.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

class Router {

    private let window: UIWindow

    init() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        self.window.backgroundColor = UIColor.white
        self.window.rootViewController = UIViewController()
        self.window.makeKeyAndVisible()
    }

    func showNewsfeed(webService: WebServiceType) {
        let controller = NewsfeedViewController(viewModel: NewsfeedViewModel(webService: webService))
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        
        self.window.rootViewController = navigationController
    }

    func showError(_ error: Error) {
        let controller = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.window.rootViewController?.present(controller, animated: true, completion: nil)
    }
}
