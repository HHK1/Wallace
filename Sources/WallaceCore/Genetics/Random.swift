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

func randomNumber(probabilities: [Double]) -> Int {

    // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
    let sum = probabilities.reduce(0, +)
    // Random number in the range 0.0 <= rnd < sum :
    let rnd = Double.random(in: 0.0 ..< sum)
    // Find the first interval of accumulated probabilities into which `rnd` falls:
    var accum = 0.0
    for (i, p) in probabilities.enumerated() {
        accum += p
        if rnd < accum {
            return i
        }
    }
    // This point might be reached due to floating point inaccuracies:
    return (probabilities.count - 1)
}


func factorial(_ n: Int) -> Int {
    if n == 0 {
        return 1
    }
    else {
        return n * factorial(n - 1)
    }
}

func poissonDistribution(lambda: Double, max: Int) -> [Double] {
    var poissonDistribution = (1...max).map({ (exp(-lambda) * pow(lambda, Double($0)))/(Double(factorial($0)))})
    poissonDistribution.insert(0, at: 0)
    return poissonDistribution
}
