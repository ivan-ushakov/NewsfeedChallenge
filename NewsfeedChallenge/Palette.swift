//
//  Palette.swift
//  NewsfeedChallenge
//
//  Created by  Ivan Ushakov on 09/11/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

extension UIColor {
    
    static func colorFromString(_ value: String) -> UIColor {
        do {
            let pattern = try NSRegularExpression(pattern: "#?([ABCDEF0-9]{2})([ABCDEF0-9]{2})([ABCDEF0-9]{2})", options: [])
            let result = pattern.matches(in: value.uppercased(), options: [], range: NSMakeRange(0, value.count))
            
            let p = result[0]
            guard let r = Int((value as NSString).substring(with: p.range(at: 1)), radix: 16) else {
                return UIColor.black
            }
            guard let g = Int((value as NSString).substring(with: p.range(at: 2)), radix: 16) else {
                return UIColor.black
            }
            guard let b = Int((value as NSString).substring(with: p.range(at: 3)), radix: 16) else {
                return UIColor.black
            }
            
            return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
        } catch {
            fatalError()
        }
    }
}
