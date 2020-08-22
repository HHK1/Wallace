//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

func generateRandomPair(count: Int) -> (Int, Int) {
    let position1 = Int.random(in: 0..<count)
    let upper: Bool

    if position1 == 0 {
        upper = true
    } else if position1 == count - 1 {
        upper = false
    } else {
        upper = Bool.random()
    }
    
    let position2 = Int.random(in: upper ? position1+1..<count : 0..<position1)
    return (position1, position2)
}
