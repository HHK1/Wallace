//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation
import Surge

func calculateMeanVector(vectors: [Vector]) -> Vector {
    guard let initial = vectors.first else { fatalError() }
    let sum = vectors.dropFirst().reduce(initial) { (lhs, rhs) -> Vector in
        return Surge.add(lhs, rhs)
    }
    return Surge.div(sum, Float(vectors.count))
}

/*
 Compute the cumulated distance between each vector of the collection
 */
func calculateDistance(vectors: [Vector]) -> Float {
    var sum: Float = 0
    for i in 0..<(vectors.count - 1) {
        for j in (i+1)..<vectors.count {
            sum += Surge.dist(vectors[i], vectors[j])
        }
    }
    return sum
}
