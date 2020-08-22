//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

func insertionMutation(chromosome: Chromosome) -> Chromosome {
    let count = chromosome.genes.count
    var genes = chromosome.genes
    let (position1, position2) = generateRandomPair(count: count)
    
    let gene1 = chromosome.genes[position1]
    let gene2 = chromosome.genes[position2]
    
    genes[position2] = gene1
    genes[position1] = gene2
    
    return Chromosome(genes: genes)
}

