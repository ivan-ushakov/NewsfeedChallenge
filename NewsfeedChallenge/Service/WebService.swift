//
//  WebService.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

struct WebServiceError: Error {
    
}

struct NewsfeedQuery {
    var startTime: Date
    var nextFrom: String?
}

extension NewsfeedQuery {
    static func begin() -> NewsfeedQuery {
        let startTime = Date().addingTimeInterval(-1 * 365 * 24 * 60 * 60)
        return NewsfeedQuery(startTime: startTime, nextFrom: nil)
    }
}

protocol WebServiceType {
    typealias Failure = (WebServiceError) -> ()
    
    func getUser(success: @escaping (User) -> (), failure: @escaping Failure)
    
    func getNewsfeed(query: NewsfeedQuery, success: @escaping (Newsfeed) -> (), failure: @escaping Failure)
    
    func loadImage(link: String, success: @escaping (Data) -> (), failure: @escaping Failure)
}

class WebService: WebServiceType {
    
    private let cacheService = CacheService()
    
    private let token: String
    
    private let session: URLSession
    
    init(token: String) {
        self.token = token
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }
    
    func getUser(success: @escaping (User) -> (), failure: @escaping Failure) {
        guard var components = URLComponents(string: "https://api.vk.com/method/users.get") else {
            fatalError()
        }
        
        components.queryItems = [URLQueryItem(name: "fields", value: "photo_100"),
                                 URLQueryItem(name: "access_token", value: self.token),
                                 URLQueryItem(name: "v", value: "5.87")]
        
        guard let url = components.url else { fatalError() }
        
        let p1 = { (user: User) in
            DispatchQueue.main.async { success(user) }
        }
        
        let p2 = { (error: WebServiceError) in
            DispatchQueue.main.async { failure(error) }
        }
        
        self.session.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            if error != nil {
                p2(WebServiceError())
                return
            }
            
            guard let responseData = data else {
                p2(WebServiceError())
                return
            }
            
            do {
                guard let object = try JSONSerialization.jsonObject(with: responseData) as? Dictionary<String, Any> else {
                    p2(WebServiceError())
                    return
                }
                
                p1(try User.transform(object))
            } catch {
                p2(WebServiceError())
            }
        }.resume()
    }
    
    func getNewsfeed(query: NewsfeedQuery, success: @escaping (Newsfeed) -> (), failure: @escaping Failure) {
        guard var components = URLComponents(string: "https://api.vk.com/method/newsfeed.get") else {
            fatalError()
        }
        
        let startTime = String(Int64(query.startTime.timeIntervalSince1970))
        
        var items = [URLQueryItem(name: "filters", value: "post"),
                     URLQueryItem(name: "return_banned", value: "0"),
                     URLQueryItem(name: "access_token", value: self.token),
                     URLQueryItem(name: "start_time", value: startTime),
                     URLQueryItem(name: "v", value: "5.87")]
        
        if let nextFrom = query.nextFrom {
            items.append(URLQueryItem(name: "start_from", value: nextFrom))
        }
        
        components.queryItems = items
        
        guard let url = components.url else { fatalError() }
        
        let p1 = { (newsfeed: Newsfeed) in
            DispatchQueue.main.async { success(newsfeed) }
        }
        
        let p2 = { (error: WebServiceError) in
            DispatchQueue.main.async { failure(error) }
        }
        
        self.session.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            if error != nil {
                p2(WebServiceError())
                return
            }
            
            guard let responseData = data else {
                p2(WebServiceError())
                return
            }
            
            do {
                guard let object = try JSONSerialization.jsonObject(with: responseData) as? Dictionary<String, Any> else {
                    p2(WebServiceError())
                    return
                }
                
                p1(try Newsfeed.transform(object))
            } catch {
                p2(WebServiceError())
            }
        }.resume()
    }
    
    func loadImage(link: String, success: @escaping (Data) -> (), failure: @escaping Failure) {
        self.cacheService.load(link) { data in
            if let p = data {
                success(p)
                return
            }
            
            guard let url = URL(string: link) else {
                failure(WebServiceError())
                return
            }
            
            self.session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    failure(WebServiceError())
                    return
                }
                
                guard let responseData = data else {
                    failure(WebServiceError())
                    return
                }
                
                success(responseData)
            }.resume()
        }
    }
}
