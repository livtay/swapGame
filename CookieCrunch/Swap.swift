//
//  Swap.swift
//  CookieCrunch
//
//  Created by Olivia Taylor on 11/7/17.
//  Copyright © 2017 oliviataylor. All rights reserved.
//


struct Swap: CustomStringConvertible, Hashable {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
    
    var hashValue: Int {
        return cookieA.hashValue ^ cookieB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) || (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
}























