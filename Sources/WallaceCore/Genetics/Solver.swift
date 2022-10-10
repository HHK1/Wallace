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
    let validateSolution: (_ generation: Int, _ parents: Set<Chromosome>) -> Chromosome?
    let makeRandomParent: (() -> Chromosome)?
    let configuration: Configuration
    let mutationDistribution: [Double]
    
    init(initialPopulation: Array<Chromosome>,
         fitness: @escaping (_ chromosome: Chromosome) -> Float,
         configuration: Configuration,
         validateSolution:  @escaping (_ generation: Int, _ parents: Set<Chromosome>) -> Chromosome?,
         makeRandomParent: (() -> Chromosome)? = nil) {
        
        self.initialPopulation = initialPopulation
        self.fitness = fitness
        self.configuration = configuration
        self.validateSolution = validateSolution
        self.makeRandomParent = makeRandomParent
        self.mutationDistribution = poissonDistribution(lambda: 1.0, max: configuration.maxNumberPermutation)
    }
    
    func run() -> Chromosome {
        var population = bootstrapInitialPopulation()
        var generation = 0
        var (fitnessScore, parents) = selectParents(population: population)
        var solution: Chromosome? = nil
        logInfo("Running solver...")
        
        while solution == nil {
            logDebug("Starting generation \(generation), fitness: \(fitnessScore)")
            population = generatePopulation(parents: parents)
            (fitnessScore, parents) = selectParents(population: population)
            solution = validateSolution(generation, parents)
            generation += 1
        }
        
        logInfo("Stopped iteration after \(generation) generations, best fit: \(self.fitness(solution!))")
        return solution!
    }
    
    func bootstrapInitialPopulation() -> Set<Chromosome> {
        var population = Set(initialPopulation)
        
        if population.count == 0 {
            assertionFailure("No initial population")
        }

      
        while population.count < configuration.populationSize {
            population.insert(self.makeRandomParent?() ?? Chromosome(genes: population.first!.genes.shuffled()))
        }
        return population
    }
    
    func generatePopulation(parents: Set<Chromosome>) -> Set<Chromosome> {
        var population = parents

        if let makeRandomParent = makeRandomParent, configuration.randomParents > 0 {
            (0...configuration.randomParents - 1).forEach({_ in population.insert(makeRandomParent()) })
        }
        
        while population.count < configuration.populationSize {
            let offsprings = createOffsprings(parents: Array(population))
            let mutatedOffsprings = generateMutations(offsprings: offsprings)
            mutatedOffsprings.forEach({ population.insert($0) })
        }
        return population
    }
    
    func selectParents(population: Set<Chromosome>) -> (Float, Set<Chromosome>) {
        var fitnessOfPopulation: [(Chromosome, Float)] = population.enumerated().map { (index, chromosome) -> (Chromosome, Float) in
            return (chromosome, self.fitness(chromosome))
        }
        fitnessOfPopulation.sort { (lhs, rhs) -> Bool in
            return lhs.1 > rhs.1
        }
        
        let selectedFitness = fitnessOfPopulation[0...configuration.parentCount - 1]        
        return (selectedFitness.first!.1, Set(selectedFitness.map{ $0.0 }))
    }
    
    func createOffsprings(parents: Array<Chromosome>) -> Array<Chromosome> {
        var offsprings: Array<Chromosome> = []        
        while offsprings.count < configuration.populationSize - parents.count {
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
