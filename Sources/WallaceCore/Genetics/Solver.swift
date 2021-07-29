//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

struct Solver {
    
    let initialPopulation: Array<Chromosome>
    let fitness: (_ chromosome: Chromosome) -> Float
    let configuration: Configuration
    let mutationDistribution: [Double]
    
    init(initialPopulation: Array<Chromosome>,
         fitness: @escaping (_ chromosome: Chromosome) -> Float,
         configuration: Configuration) {
        
        self.initialPopulation = initialPopulation
        self.fitness = fitness
        self.configuration = configuration
        self.mutationDistribution = poissonDistribution(lambda: 1.0, max: configuration.maxNumberPermutation)
    }
    
    func run() -> Chromosome {
        var population = initialPopulation
        var generation = 0
        
        logInfo("Starting solver...")
        
        while generation < configuration.maxGenerations {
            logDebug("Starting generation \(generation)")
            var parents = selectParents(population: population)
            let offsprings = createOffsprings(parents: parents)
            let mutatedOffsprings = generateMutations(offsprings: offsprings)
            parents.append(contentsOf: mutatedOffsprings)
            population = parents
            generation += 1
        }
        
        logInfo("Stopped iteration after \(generation) generations")
        let bestFit = selectParents(population: population).first!
        logInfo("Best fit is: \(self.fitness(bestFit))")
        return bestFit
    }
    
    func selectParents(population: Array<Chromosome>) -> Array<Chromosome> {
        var fitnessOfPopulation: [(Int, Float)] = population.enumerated().map { (index, chromosome) -> (Int, Float) in
            return (index, self.fitness(chromosome))
        }
        fitnessOfPopulation.sort { (lhs, rhs) -> Bool in
            return lhs.1 > rhs.1
        }
        
        let selectedFitness = fitnessOfPopulation[0...configuration.parentCount - 1]
        logVerbose("Fitness score: \(selectedFitness.first!.1)")
        
        var parents = selectedFitness.map{ population[$0.0] }
        parents.append(population[fitnessOfPopulation.last!.0])
        return parents
    }
    
    func createOffsprings(parents: Array<Chromosome>) -> Array<Chromosome> {
        var offsprings: [Chromosome] = []
        
        while offsprings.count < configuration.populationSize + parents.count {
            let randomPair = generateRandomPair(count: parents.count)
            let offspring = orderCrossover(parent1: parents[randomPair.0], parent2: parents[randomPair.1])
            offsprings.append(offspring)
        }
        return offsprings
    }
    
    func generateMutations(offsprings: Array<Chromosome>) -> Array<Chromosome> {
        var mutatedOffspring: [Chromosome] = []
        offsprings.forEach { (offspring) in
            if Float.random(in: 0...1) < configuration.mutationProbability {
                mutatedOffspring.append(multiInsertionMutation(chromosome: offspring,
                                                               distribution: mutationDistribution))
            } else {
                mutatedOffspring.append(offspring)
            }
        }
        return mutatedOffspring
    }
}
