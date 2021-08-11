import XCTest
import class Foundation.Bundle
@testable import WallaceCore

final class WallaceTests: XCTestCase {
    
    func testInsertionMutation() {
        
        let genesSet: Set<UInt8> = Set([0x00, 0x01, 0x02, 0x03, 0x04])
        let chromosome = Chromosome(genes: [0x00, 0x01, 0x02, 0x03, 0x04])
        
        let offspring = insertionMutation(chromosome: chromosome)
        let offspringGenesSet = Set(offspring.genes)
        XCTAssertEqual(genesSet, offspringGenesSet)
        XCTAssertNotEqual(chromosome.genes, offspring.genes)
        XCTAssertEqual(chromosome.genes.count, offspring.genes.count)
    }

    func testCrossover() {
        
        let genesSet: Set<UInt8> = Set([0x00, 0x01, 0x02, 0x03, 0x04])
        let chromosome1 = Chromosome(genes: [0x00, 0x01, 0x02, 0x03, 0x04])
        let chromosome2 = Chromosome(genes: [0x01, 0x02, 0x03, 0x04, 0x00])
        
        let offspring = orderCrossover(parent1: chromosome1, parent2: chromosome2)
        print(offspring)
        let offspringGenesSet = Set(offspring.genes)
        XCTAssertEqual(genesSet, offspringGenesSet)
        XCTAssertEqual(chromosome1.genes.count, offspring.genes.count)
    }
    
    func testBasicSolver() {
        
       func fitness(chromosome: Chromosome) -> Float {
           let first = Int(chromosome.genes.first!)
           let last = Int(chromosome.genes.last!)
           return Float(first - last)
       }
       
        func shouldStopReproduction(solution: Chromosome, generation: Int) -> Bool {
            return generation == 100
        }
        let chromosome = Chromosome(genes: (1...20).map { $0 })
        let initialPopulation = Array(repeating: chromosome, count: 10)
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.2, maxGenerations: 100, parentCount: 10, maxNumberPermutation: 3)
        let solver = Solver(initialPopulation: initialPopulation, fitness: fitness, configuration: configuration, shouldStopReproduction: shouldStopReproduction)
       let bestFit = solver.run()
       XCTAssertEqual(bestFit.genes.first, 20)
       XCTAssertEqual(bestFit.genes.last, 1)

    }
    
    func testVectorMean() {
        let vector1: [Float] = [0.0, 0.0, 6.0, 3.0]
        let vector2: [Float] = [1.0, 0.0, 0.0, 3.0]
        let vector3: [Float] = [2.0, 0.0, 0.0, 3.0]
        
        let mean = calculateMeanVector(vectors: [vector1, vector2, vector3])
        let expected: [Float] = [1.0, 0.0, 2.0, 3.0]
        XCTAssertEqual(mean, expected)
    }
    
    func testVectorDistance() {
        let vector1: [Float] = [0.0, 0.0, 6.0, 3.0]
        let vector2: [Float] = [1.0, 0.0, 0.0, 3.0]
        let vector3: [Float] = [2.0, 0.0, 0.0, 3.0]
    
        let mean = calculateDistance(vectors: [vector1, vector2, vector3])
        let expected = sqrt(37) + sqrt(40) + sqrt(1)
        XCTAssertEqual(Double(mean), expected, accuracy: 1e-6)
    }
    
    func testGrouping() {
        
        struct TestStudent: Student {
            static func isSolutionValid(students: Array<TestStudent>, groups: [Array<TestStudent>]) -> Bool {
                return true
            }
            
            let id: UInt8
            let knowsSwift: Bool
            
            init(id: UInt8, knowsSwift: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
            }
            
            static var verificationPaths: [KeyPath<TestStudent, Bool>] {
                return [\.knowsSwift]
            }
            
            func makeAttributeVector(factors: [Float]) -> Vector {
                return [(self.knowsSwift ? 1 : 0) * factors[0]]
            }
            var description: String {
                return "\(self.id)"
            }
        }
        
        let students = (1...9).map({ TestStudent(id: $0, knowsSwift: ($0 % 3) == 0 )})
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.2, maxGenerations: 100, parentCount: 10, maxNumberPermutation: 3)
        let grouping = Grouping(students: students, factors: [1.0], groupSize: 3, configuration: configuration)
        let groups = grouping.run()
        XCTAssertEqual(groups.count, 3)
    }
    
    
    func testRotation() {
        let groupSize = 4
        let numberOfRotations = 4
        let rotations = createGroupRotations(populationSize: 120, groupSize: groupSize, numberOfRotations: numberOfRotations)

        XCTAssertEqual(rotations.count, numberOfRotations)
        rotations.forEach { (rotation) in
            XCTAssertEqual(rotation.count, 120 / groupSize)
            rotation.forEach({ XCTAssertEqual($0.count, groupSize)})
        }
    }
    
    func testVerification() {
        struct TestStudent: Student {
            let id: UInt8
            let knowsSwift: Bool
            let knowsC: Bool
            let knowsObjectiveC: Bool
            
            init(id: UInt8, knowsSwift: Bool, knowsC: Bool, knowsObjectiveC: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
                self.knowsObjectiveC = knowsObjectiveC
                self.knowsC = knowsC
            }
            
            static var verificationPaths: [KeyPath<TestStudent, Bool>] {
                return [\.knowsSwift, \.knowsC, \.knowsObjectiveC]
            }
            
            static func isSolutionValid(students: Array<TestStudent>, groups: [Array<TestStudent>]) -> Bool {
                return true
            }
            
            func makeAttributeVector(factors: [Float]) -> Vector {
                return zip(TestStudent.verificationPaths, factors).map { (path, factor) -> Float in
                    factor * (self[keyPath: path] ? 1 : 0)
                }
            }
            var description: String {
                return "\(self.id)"
            }
        }
        
        let swiftStudent = TestStudent(id: 0, knowsSwift: true, knowsC: false, knowsObjectiveC: false)
        let cStudent = TestStudent(id: 1, knowsSwift: false, knowsC: true, knowsObjectiveC: false)
        let objcStudent = TestStudent(id: 2, knowsSwift: false, knowsC: false, knowsObjectiveC: true)
        let oldIosDev = TestStudent(id:3, knowsSwift: false, knowsC: true, knowsObjectiveC: true)
        let juniorStudent = TestStudent(id: 4, knowsSwift: false, knowsC: false, knowsObjectiveC: false)
            
        let students = [swiftStudent, cStudent, objcStudent, oldIosDev, oldIosDev, juniorStudent]
        let validGroups = [[swiftStudent, cStudent, objcStudent], [oldIosDev, oldIosDev, juniorStudent]]
        
        XCTAssertTrue(TestStudent.areGroupsValid(students: students, groups: validGroups))
        
        let students2 = [swiftStudent, swiftStudent, swiftStudent, swiftStudent, cStudent, cStudent, objcStudent, oldIosDev, oldIosDev]
        let validGroups2 = [[swiftStudent, cStudent, oldIosDev], [swiftStudent, cStudent, objcStudent], [swiftStudent, swiftStudent, oldIosDev]]
        
        XCTAssertTrue(TestStudent.areGroupsValid(students: students2, groups: validGroups2))
        
        let invalidGroups = [[swiftStudent, swiftStudent , oldIosDev], [cStudent, cStudent, objcStudent], [swiftStudent, swiftStudent, oldIosDev]]
        let invalidGroups2 = [[swiftStudent, cStudent, oldIosDev], [swiftStudent, oldIosDev, objcStudent], [swiftStudent, swiftStudent, cStudent]]
        XCTAssertFalse(TestStudent.areGroupsValid(students: students2, groups: invalidGroups))
        XCTAssertFalse(TestStudent.areGroupsValid(students: students2, groups: invalidGroups2))
    }
    
    static var allTests = [
        ("testInsertionMutation", testInsertionMutation),
        ("testBasicSolver", testBasicSolver),
        ("testCrossover", testCrossover),
        ("testGrouping", testGrouping),
        ("testRotation", testRotation),
    ]
}
