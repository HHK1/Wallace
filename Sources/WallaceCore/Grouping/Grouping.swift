//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

public typealias Vector = [Float]
typealias StudentGroup = [Vector]

public protocol Student {
    var id: UInt8 { get }
    func makeAttributeVector(factors: [Float]) -> Vector 
    var description: String { get }
}

/**
    A class to solve the NP hard problem of assigning students to groups, while maximising the heterogeneity of the groups.
    Students are being represented by Ids encoded in UInt8, so it's a maximum of 256 students.
    
    A vector of parameters should be associated to each student, representing its features. The algorithm is going to place students
    so that groups are heterogenous along each  dimension. You can pass an array of factors to emphasis the necessity of separating students along
    a specific dimension
 */
public class Grouping<StudentType: Student> {
    private let students: [UInt8]
    private let studentsMap: Dictionary<UInt8, StudentType>
    private let vectorsMap: Dictionary<UInt8, Vector>
    private let groupSize: Int
    private let configuration: Configuration
    
    public init(students: [StudentType], factors: [Float], groupSize: Int, configuration: Configuration) {
        self.students = students.map({ $0.id })
        self.studentsMap = Dictionary(uniqueKeysWithValues: students.map{ ($0.id, $0)})
        self.vectorsMap = Dictionary(uniqueKeysWithValues: students.map{ ($0.id, $0.makeAttributeVector(factors: factors))})
        self.groupSize = groupSize
        self.configuration = configuration
    }
    
    private func makeInitialPopulation(count: Int) -> Array<Chromosome> {
        return (0...count).map({ _ in Chromosome(genes: self.students.shuffled()) })
    }
    
    private func fitness(chromosome: Chromosome) -> Float {
        let groups = makeGroups(chromosome: chromosome)
        let groupMeans = groups.map({ calculateMeanVector(vectors: $0) })
        let distance = calculateDistance(vectors: groupMeans)
        return 1 / distance
    }
    
    private func makeGroups(chromosome: Chromosome) -> Array<StudentGroup> {
        return chromosome.genes.map({ vectorsMap[$0]! }).chunked(into: groupSize)
    }
    
    public func run() -> Array<Array<StudentType>> {
        var population: Array<Chromosome> = []
        for _ in 0...configuration.parentCount {
            let solver  = Solver(initialPopulation: makeInitialPopulation(count: configuration.populationSize),
                                 fitness: self.fitness(chromosome:), configuration: configuration)
            
            let finalChromosome =  solver.run()
            population.append(finalChromosome)
        }
        let solver  = Solver(initialPopulation: population,
                             fitness: self.fitness(chromosome:), configuration: configuration)
        
        let finalChromosome =  solver.run()
        return finalChromosome.genes.map({ studentsMap[$0]! }).chunked(into: groupSize)
    }
}
