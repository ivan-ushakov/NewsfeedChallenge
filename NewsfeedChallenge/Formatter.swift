//
//  Formatter.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 11/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

class Formatter {
    
    public static let shared = Formatter()
    
    private let f1 = DateFormatter()
    private let f2 = NumberFormatter()
    
    init() {
        self.f1.dateStyle = .medium
        self.f1.timeStyle = .short
        self.f1.doesRelativeDateFormatting = true
        
        self.f2.maximumFractionDigits = 1
        self.f2.roundingMode = .down
    }
    
    func f(_ value: Date) -> String {
        return self.f1.string(from: value)
    }
    
    func f(_ value: Int) -> String {
        let d = Double(value)
        
        let suffix = [(1000.0, "K"), (1000000.0, "M"), (1000000000.0, "G")]
        for i in 0..<suffix.count {
            if d < suffix[i].0 {
                let p = i - 1
                if p < 0 {
                    return String(value)
                }
                
                let n = d / suffix[p].0 as NSNumber
                return (self.f2.string(from: n) ?? "1") + suffix[p].1
            }
        }
        
        return "1"
    }
}
