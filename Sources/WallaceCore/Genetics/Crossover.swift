//
//  Crossover.swift
//
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

func orderCrossover(parent1: Chromosome, parent2: Chromosome) -> Chromosome {
    let count = parent1.genes.count
    var protoChild = Array<UInt8?>(repeating: nil, count: count)
    
    let range = makeRandomRange(count: count)
    
    let parent1GenesCopy = parent1.genes as [UInt8?]
    let subRange = parent1GenesCopy[range]
    protoChild.replaceSubrange(range, with: subRange)
    
    var missingGenes = parent2.genes.filter { !subRange.contains($0) }
    let genes = protoChild.map { return $0 ?? missingGenes.removeFirst()}
    return Chromosome.init(genes: genes)
}

private func makeRandomRange(count: Int) -> ClosedRange<Int> {
    let lowerRange = Int.random(in: 0..<count)
    let upperRange = Int.random(in: lowerRange..<count)
    return lowerRange...upperRange
}
