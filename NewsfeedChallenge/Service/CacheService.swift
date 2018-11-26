//
//  CacheService.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 11/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

class CacheService {
    
    private let cache = NSCache<NSString, NSData>()
    
    func load(_ link: String, callback: @escaping (Data?) -> ()) {
        guard let key = link.sha1 else {
            callback(nil)
            return
        }
        
        if let data = self.cache.object(forKey: key as NSString) as Data? {
            callback(data)
            return
        }
        
        DispatchQueue.global().async {
            let path = self.createPath(key)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                DispatchQueue.main.async {
                    self.cache.setObject(data as NSData, forKey: key as NSString)
                    callback(data)
                }
            } catch {
                DispatchQueue.main.async { callback(nil) }
            }
        }
    }
    
    func save(_ link: String, data: Data) {
        guard let key = link.sha1 else {
            return
        }
        
        self.cache.setObject(data as NSData, forKey: key as NSString)
        
        DispatchQueue.global().async {
            let path = self.createPath(key)
            do {
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            } catch {
                print("Cache: fail to write")
            }
        }
    }
    
    private func createPath(_ hash: String) -> String {
        guard let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            fatalError()
        }
        
        return NSString(string: cachePath).appendingPathComponent(hash)
    }
}
