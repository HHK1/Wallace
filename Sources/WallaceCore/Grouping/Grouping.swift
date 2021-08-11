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
    var description: String { get }
    func makeAttributeVector(factors: [Float]) -> Vector
    static var verificationPaths: [KeyPath<Self, Bool>] { get }
    static func isSolutionValid(students: Array<Self>, groups: [Array<Self>]) -> Bool
}

/**
    A class to solve the NP hard problem of assigning students to groups, while maximising the heterogeneity of the groups.
    Students are being represented by Ids encoded in UInt8, so it's a maximum of 256 students.
    
    A vector of parameters should be associated to each student, representing its features. The algorithm is going to place students
    so that groups are heterogenous along each  dimension. You can pass an array of factors to emphasis the necessity of separating students along
    a specific dimension
 */
public class Grouping<StudentType: Student> {
    private let students: [StudentType]
    private let studentsMap: Dictionary<UInt8, StudentType>
    private let vectorsMap: Dictionary<UInt8, Vector>
    private let groupSize: Int
    private let configuration: Configuration
    
    public init(students: [StudentType], factors: [Float], groupSize: Int, configuration: Configuration) {
        self.students = students
        self.studentsMap = Dictionary(uniqueKeysWithValues: students.map{ ($0.id, $0)})
        self.vectorsMap = Dictionary(uniqueKeysWithValues: students.map{ ($0.id, $0.makeAttributeVector(factors: factors))})
        self.groupSize = groupSize
        self.configuration = configuration
    }
    
    private func makeInitialPopulation(count: Int) -> Array<Chromosome> {
        return (0...count).map({ _ in Chromosome(genes: self.students.map({ $0.id }).shuffled()) })
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
        
        func shouldStopReproduction(solution: Chromosome, generation: Int) -> Bool {
            if (generation <= configuration.maxGenerations) { return false }
            let groups = solution.genes.map({ studentsMap[$0]! }).chunked(into: groupSize)
            return StudentType.isSolutionValid(students: self.students, groups: groups)
        }
        let initialPopulation = generateInitialPopulation()
        let solver  = Solver(initialPopulation: initialPopulation,
                             fitness: self.fitness(chromosome:),
                             configuration: configuration,
                             shouldStopReproduction: shouldStopReproduction)
        
        logInfo("Starting last generation")
        let finalChromosome = solver.run()
        return finalChromosome.genes.map({ studentsMap[$0]! }).chunked(into: groupSize)
    }
    
    private func generateInitialPopulation() -> Array<Chromosome> {
        var population: Array<Chromosome> = []
        
        func shouldStopReproduction(solution: Chromosome, generation: Int) -> Bool {
            return generation == configuration.maxGenerations / configuration.parentCount
        }
        
        for _ in 0...configuration.parentCount {
            let initialPopulation = makeInitialPopulation(count: configuration.populationSize)
            let solver  = Solver(initialPopulation: initialPopulation,
                                 fitness: self.fitness,
                                 configuration: configuration,
                                 shouldStopReproduction: shouldStopReproduction)
            
            let finalChromosome = solver.run()
            population.append(finalChromosome)
        }
        return population
    }
}

/*
    Verification
 */

extension Student {
    
    public static func areGroupsValid(students: Array<Self>, groups: [Array<Self>]) -> Bool {
        guard let groupSize = groups.first?.count else { return false }
        let numberOfGroups = groups.count
        
        let matches = verificationPaths.map { (path) -> Bool in
            let numberOfStudents = students.filter({ $0[keyPath: path] == true }).count
            let expectedDistribution = groupDistribution(students: numberOfStudents, numberOfGroups: numberOfGroups, groupSize: groupSize)
            var distribution = Array.init(repeating: 0, count: groupSize + 1)

            distribution = groups.reduce(distribution) { (acc, group) -> Array<Int> in
                let matchingStudentsInGroup = group.filter({ $0[keyPath: path ] == true }).count
                var next = acc
                next[matchingStudentsInGroup] += 1
                return next
            }
            let isPathValid = expectedDistribution == distribution
            logVerbose("Path \(path.hashValue) is valid: \(isPathValid)")
            logVerbose("Distribution \(distribution), expected: \(expectedDistribution)")
            return isPathValid
        }
        
        return matches.filter({ $0 == false }).isEmpty
    }
    
    /* Given a number of students, the total number of groups and the desired groupSize,
     return an array representing the distribution of these students in the overall groups */
    static func groupDistribution(students: Int, numberOfGroups: Int, groupSize: Int) -> Array<Int> {
        var distribution = Array.init(repeating: 0, count: groupSize + 1)
        
        let remainder = students % numberOfGroups
        let wholePart = students - remainder
        let studentPerGroup = wholePart / numberOfGroups
        distribution[studentPerGroup] = numberOfGroups - remainder
        if remainder != 0 {
            distribution[studentPerGroup + 1] = remainder
        }
        return distribution
    }
}
