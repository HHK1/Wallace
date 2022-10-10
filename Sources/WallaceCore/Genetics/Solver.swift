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
    let shouldStopReproduction: (_ solution: Chromosome, _ generation: Int) -> Bool
    let configuration: Configuration
    let mutationDistribution: [Double]
    
    init(initialPopulation: Array<Chromosome>,
         fitness: @escaping (_ chromosome: Chromosome) -> Float,
         configuration: Configuration,
         shouldStopReproduction:  @escaping (_ solution: Chromosome, _ generation: Int) -> Bool) {
        
        self.initialPopulation = initialPopulation
        self.fitness = fitness
        self.configuration = configuration
        self.shouldStopReproduction = shouldStopReproduction
        self.mutationDistribution = poissonDistribution(lambda: 1.0, max: configuration.maxNumberPermutation)
    }
    
    func run() -> Chromosome {
        var population = initialPopulation
        var generation = 0
        var parents = selectParents(population: population)
        var bestFit = parents.first!
        logInfo("Running solver...")
        
        while !shouldStopReproduction(bestFit, generation) {
            logDebug("Starting generation \(generation)")
            let offsprings = createOffsprings(parents: parents)
            let mutatedOffsprings = generateMutations(offsprings: offsprings)
            parents.append(contentsOf: mutatedOffsprings)
            population = parents
            generation += 1
            parents = selectParents(population: population)
            bestFit = parents.first!
        }
        
        logInfo("Stopped iteration after \(generation) generations, best fit: \(self.fitness(bestFit))")
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
        logDebug("Fitness score: \(selectedFitness.first!.1)")
        
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
