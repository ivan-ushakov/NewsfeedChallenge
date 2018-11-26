//
//  AuthService.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

import VK_ios_sdk

struct AuthServiceError: Error {
    
}

protocol AuthServiceType {
    func auth(success: @escaping (String) -> (), failure: @escaping (AuthServiceError) -> ())
    
    func processOpen(url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
}

class AuthService: NSObject, AuthServiceType, VKSdkDelegate {
    
    private let scope = ["wall", "friends"]
    
    private var success: ((String) -> ())?
    
    private var failure: ((AuthServiceError) -> ())?
    
    override init() {
        super.init()
        
        VKSdk.initialize(withAppId: "6746411")?.register(self)
    }
    
    func auth(success: @escaping (String) -> (), failure: @escaping (AuthServiceError) -> ()) {
        VKSdk.wakeUpSession(self.scope) { [weak self] (state, error) in
            switch state {
            case .initialized:
                print("AuthService: initialized")
                self?.start(success: success, failure: failure)
                break
                
            case .authorized:
                print("AuthService: authorized")
                if let token = VKSdk.accessToken() {
                    success(token.accessToken)
                } else {
                    failure(AuthServiceError())
                }
                break
                
            default:
                failure(AuthServiceError())
                break
            }
        }
    }
    
    func processOpen(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        if let application = options[.sourceApplication] as? String {
            VKSdk.processOpen(url, fromApplication: application)
        }
    }
    
    // MARK: Private
    private func start(success: @escaping (String) -> (), failure: @escaping (AuthServiceError) -> ()) {
        self.success = success
        self.failure = failure
        
        VKSdk.authorize(self.scope)
    }
}

extension AuthService {
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if let token = result.token {
            self.success?(token.accessToken)
        } else {
            self.failure?(AuthServiceError())
        }
    }
    
    func vkSdkUserAuthorizationFailed() {
        self.failure?(AuthServiceError())
    }
}
