//
//  File.swift
//  
//
//  Created by Henry Huck on 21/08/2020.
//

import Foundation

public typealias Vector = [Float]
typealias StudentGroup = [Vector]
public typealias Factors<T: Student> = Dictionary<KeyPath<T, Bool>, Int>

public protocol Student: Hashable, Equatable {
    var id: UInt8 { get }
    var description: String { get }
    func makeHeterogeneousAttributeVector(factors: Factors<Self>) -> Vector
    func makeHomogenenousAttributeVector(factors: Factors<Self>) -> Vector
}

public extension Student {
    func makeHeterogeneousAttributeVector(factors: Factors<Self>) -> Vector {
        return factors.keys.map({ self[keyPath: $0] ? Float(factors[$0]!) : 0 })
    }
    
    func makeHomogenenousAttributeVector(factors: Factors<Self>) -> Vector {
        return factors.keys.map({ self[keyPath: $0] ? Float(factors[$0]!) : 0 })
    }
    
    var description: String {
        return "\(self.id)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: any Student, rhs: any Student) -> Bool {
        return lhs.id == rhs.id
    }
}

/**
    A class to solve the NP hard problem of assigning students to groups, while maximising the heterogeneity of the groups.
    Students are being represented by Ids encoded in UInt8, so it's a maximum of 256 students.
    
    A vector of parameters should be associated to each student, representing its features. The algorithm is going to place students
    so that groups are heterogenous along each  dimension. You have to specify a dictionary of keyPaths with weights for both the factors that should maximize heterogeneity
    and for factors that should maximize homogeneity.
 
    Optionally you can specify an object that will verify if the solution is valid.
 */
public class Grouping<StudentType: Student> {
    private let students: [StudentType]
    private let studentsMap: Dictionary<UInt8, StudentType>
    private let heterogeneousFactors: Factors<StudentType>?
    private let homogeneousFactors: Factors<StudentType>?
    private let heterogeneousVectorsMap: Dictionary<UInt8, Vector>?
    private let homogenenousVectorsMap: Dictionary<UInt8, Vector>?
    private let groupSize: Int
    private let configuration: Configuration
    private let verify: Verification<StudentType>?
    
    /**
    An array of functions used to split the students into groups matching the homogeneity criteria. Set as an instance variable to avoid
    recomputing them for every chromosome generation
     */
    private let homogeneousSortFunctions: Array<(_: StudentType) -> Bool>?
    
    public init(students: [StudentType],
                heterogeneousFactors: Factors<StudentType>?,
                homogeneousFactors: Factors<StudentType>?,
                groupSize: Int,
                configuration: Configuration,
                verify: Verification<StudentType>? = nil) {
        
        self.students = students
        self.studentsMap = Dictionary(uniqueKeysWithValues: students.map{ ($0.id, $0)})
        self.heterogeneousFactors = heterogeneousFactors
        self.homogeneousFactors = homogeneousFactors
        
        if let heterogeneousFactors = heterogeneousFactors {
            let vectors = students.map{ ($0.id, $0.makeHeterogeneousAttributeVector(factors: heterogeneousFactors ))}
            self.heterogeneousVectorsMap = Dictionary(uniqueKeysWithValues: vectors)
        } else {
            self.heterogeneousVectorsMap = nil
        }
        if let homogeneousFactors = homogeneousFactors {
            let vectors = students.map{ ($0.id, $0.makeHomogenenousAttributeVector(factors: homogeneousFactors ))}
            self.homogenenousVectorsMap = Dictionary(uniqueKeysWithValues: vectors)
        } else {
            self.homogenenousVectorsMap = nil
        }
        
        self.groupSize = groupSize
        self.configuration = configuration
        self.verify = verify == nil ? nil : memoize(verify!)
        
        let initialValue: Array<(StudentType) -> Bool> = []
        self.homogeneousSortFunctions = self.homogeneousFactors?.reduce(initialValue, { (groupFunctions, factor) in
            
            let (key, _) = factor
            let trueCondition = { (student: StudentType) -> Bool in return student[keyPath: key] == true }
            let falseCondition = { (student: StudentType) -> Bool in return student[keyPath: key] == false }
            if (groupFunctions.count == 0) {
                return [trueCondition, falseCondition]
            }
            let trueSubgroup = groupFunctions.map { (function) in
                return { (student: StudentType) -> Bool in return function(student) && trueCondition(student) }
            }
            let falseSubGroup = groupFunctions.map { (function) in
                return { (student: StudentType) -> Bool in return function(student) && falseCondition(student) }
            }
            return trueSubgroup + falseSubGroup
        })
    }
    
    func makeInitialPopulation(count: Int) -> Array<Chromosome> {
        return (1...count).map({ _ in makeRandomParent() })
    }
    
    func makeRandomParent() -> Chromosome {
        return makeChromosomeSortedByHomogeneity()
    }
    
    private func makeChromosomeSortedByHomogeneity() -> Chromosome {
        guard let sortFunctions = self.homogeneousSortFunctions, !sortFunctions.isEmpty else {
            return Chromosome(genes: self.students.map({ $0.id }).shuffled())
        }
                    
        let population = sortFunctions.map({ (sortFunction) in
            return self.students.filter { (student) -> Bool in
                return sortFunction(student)
            }.shuffled()
        }).flatMap({ $0 })
        return Chromosome(genes: population.map({ $0.id }))
    }
    
    private func fitness(chromosome: Chromosome) -> Float {
        return heterogeneousFitness(chromosome: chromosome) + homogeneousFitness(chromosome: chromosome)
    }
    
    private func heterogeneousFitness(chromosome: Chromosome) -> Float {
        guard let vectorsMap = heterogeneousVectorsMap else { return 0 }
        let vectorGroups = chromosome.genes.map({ vectorsMap[$0]! }).chunked(into: groupSize)
        let groupMeans = vectorGroups.map({ calculateMeanVector(vectors: $0) })
        let distance = calculateDistance(vectors: groupMeans)
        return -distance
    }
    
    private func homogeneousFitness(chromosome: Chromosome) -> Float {
        guard let vectorsMap = homogenenousVectorsMap else { return 0 }
        let vectorGroups = chromosome.genes.map({ vectorsMap[$0]! }).chunked(into: groupSize)
        let groupMeans = vectorGroups.map({ calculateMeanVector(vectors: $0) })
        let distance = calculateDistance(vectors: groupMeans)
        return distance
    }
    
    public func run() -> Array<Array<StudentType>> {
        func validateSolution(generation: Int, parents: Set<Chromosome>) -> Chromosome? {
            if (generation <= configuration.maxGenerations) { return nil }
            guard let verify = verify else { return parents.first }
            
            let solution = parents.first(where: { (chromosom) in
                let groups = chromosom.genes.map({ studentsMap[$0]! }).chunked(into: groupSize)
                return verify(groups)
            })
            
            return solution
            
        }
        let initialPopulation = makeInitialPopulation(count: configuration.populationSize)
        let solver = Solver(initialPopulation: initialPopulation,
                             fitness: self.fitness(chromosome:),
                             configuration: configuration,
                             validateSolution: validateSolution,
                             makeRandomParent: self.makeRandomParent)
        
        let finalChromosome = solver.run()
        return finalChromosome.genes.map({ studentsMap[$0]! }).chunked(into: groupSize)
    }
}
