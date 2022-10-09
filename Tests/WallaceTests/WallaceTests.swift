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
            
            let id: UInt8
            let knowsSwift: Bool
            let knowsObjc: Bool
            
            init(id: UInt8, knowsSwift: Bool, knowsObjc: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
                self.knowsObjc = knowsObjc
            }
        }
        
        let students = (1...9).map({ TestStudent(id: $0, knowsSwift: ($0 % 3) == 0, knowsObjc: ($0 % 3) == 1 )})
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.5, maxGenerations: 50, parentCount: 10, maxNumberPermutation: 3)
        let grouping = Grouping(students: students,
                                heterogeneousFactors: [\TestStudent.knowsSwift: 1, \TestStudent.knowsObjc: 1],
                                homogeneousFactors: nil, groupSize: 3, configuration: configuration)
        
        let groups = grouping.run()
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].filter({ $0.knowsSwift }).count, 1)
        XCTAssertEqual(groups[1].filter({ $0.knowsSwift }).count, 1)
        XCTAssertEqual(groups[2].filter({ $0.knowsSwift }).count, 1)
    }
    
    func testHomogeneousGrouping() {
        struct TestStudent: Student {
            
            let id: UInt8
            let knowsSwift: Bool
            let knowsObjc: Bool
            
            init(id: UInt8, knowsSwift: Bool, knowsObjc: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
                self.knowsObjc = knowsObjc
            }
        }
        
        let students = (1...9).map({ TestStudent(id: $0, knowsSwift: ($0 % 3) == 0, knowsObjc: ($0 % 3) == 1 )})
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.5, maxGenerations: 50, parentCount: 10, maxNumberPermutation: 3)
        let grouping = Grouping(students: students,
                                heterogeneousFactors: [\TestStudent.knowsSwift: 1],
                                homogeneousFactors: [\TestStudent.knowsObjc: 1], groupSize: 3,
                                configuration: configuration)
        
        let groups = grouping.run()
        XCTAssertEqual(groups.count, 3)
        let objCGroup = groups.first(where: { $0.first!.knowsObjc == true })
        XCTAssertEqual(objCGroup?.filter({ $0.knowsObjc }).count, 3)
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
        }
        
        let factors = [\TestStudent.knowsSwift: 1, \TestStudent.knowsObjectiveC: 1, \TestStudent.knowsC: 1]
        let swiftStudent = TestStudent(id: 0, knowsSwift: true, knowsC: false, knowsObjectiveC: false)
        let cStudent = TestStudent(id: 1, knowsSwift: false, knowsC: true, knowsObjectiveC: false)
        let objcStudent = TestStudent(id: 2, knowsSwift: false, knowsC: false, knowsObjectiveC: true)
        let oldIosDev = TestStudent(id:3, knowsSwift: false, knowsC: true, knowsObjectiveC: true)
        let juniorStudent = TestStudent(id: 4, knowsSwift: false, knowsC: false, knowsObjectiveC: false)
            
        let validGroups = [[swiftStudent, cStudent, objcStudent], [oldIosDev, oldIosDev, juniorStudent]]
        
        XCTAssertTrue(Verifier.areGroupsValid(groups: validGroups, heterogeneousFactors: factors))
        
        let validGroups2 = [[swiftStudent, cStudent, oldIosDev], [swiftStudent, cStudent, objcStudent], [swiftStudent, swiftStudent, oldIosDev]]
        
        XCTAssertTrue(Verifier.areGroupsValid(groups: validGroups2, heterogeneousFactors: factors))
        
        let invalidGroups = [[swiftStudent, swiftStudent , oldIosDev], [cStudent, cStudent, objcStudent], [swiftStudent, swiftStudent, oldIosDev]]
        let invalidGroups2 = [[swiftStudent, cStudent, oldIosDev], [swiftStudent, oldIosDev, objcStudent], [swiftStudent, swiftStudent, cStudent]]
        XCTAssertFalse(Verifier.areGroupsValid(groups: invalidGroups, heterogeneousFactors: factors))
        XCTAssertFalse(Verifier.areGroupsValid(groups: invalidGroups2, heterogeneousFactors: factors))
    }
    
    func testVerificationWithHomogeneity() {
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
            
            
        }
        
       
        let swiftStudent = TestStudent(id: 0, knowsSwift: true, knowsC: false, knowsObjectiveC: false)
        let cStudent = TestStudent(id: 1, knowsSwift: false, knowsC: true, knowsObjectiveC: false)
        let objcStudent = TestStudent(id: 2, knowsSwift: false, knowsC: false, knowsObjectiveC: true)
        let oldIosDev = TestStudent(id:3, knowsSwift: false, knowsC: true, knowsObjectiveC: true)
        let juniorStudent = TestStudent(id: 4, knowsSwift: false, knowsC: false, knowsObjectiveC: false)
            
        let validGroups = [[swiftStudent, juniorStudent, objcStudent], [oldIosDev, oldIosDev, cStudent]]
        let invalidGroups = [[swiftStudent, cStudent, objcStudent], [oldIosDev, oldIosDev, juniorStudent]]

        XCTAssertTrue(Verifier.areGroupsValid(groups: validGroups,
                                              heterogeneousFactors: [\TestStudent.knowsSwift: 1, \TestStudent.knowsObjectiveC: 1],
                                              homogeneousFactors: [\TestStudent.knowsC: 1]))
        XCTAssertFalse(Verifier.areGroupsValid(groups: invalidGroups,
                                              heterogeneousFactors: [\TestStudent.knowsSwift: 1, \TestStudent.knowsObjectiveC: 1],
                                              homogeneousFactors: [\TestStudent.knowsC: 1]))
    }
    
    func testInitialPopulationSingleHomogeneityCriteria() {
        struct TestStudent: Student {
            
            let id: UInt8
            let knowsSwift: Bool
            let knowsObjc: Bool
            
            init(id: UInt8, knowsSwift: Bool, knowsObjc: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
                self.knowsObjc = knowsObjc
            }
        }
        
        let students = (1...120).map({ TestStudent(id: $0, knowsSwift: ($0 % 3) == 0, knowsObjc: ($0 <= 70) )})
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.5, maxGenerations: 50, parentCount: 10, maxNumberPermutation: 3)
        let grouping = Grouping(students: students.shuffled(),
                                heterogeneousFactors: [\TestStudent.knowsSwift: 1],
                                homogeneousFactors: [\TestStudent.knowsObjc: 1], groupSize: 3,
                                configuration: configuration)
        
        let parents = grouping.makeInitialPopulation(count: 2)
        let firstParent = parents[0]
        let secondParent = parents[1]
        
        XCTAssert(firstParent.genes[0...69].allSatisfy({ $0 <= 70}))
        XCTAssert(firstParent.genes[70...119].allSatisfy({ $0 > 70}))

        XCTAssert(secondParent.genes[0...69].allSatisfy({ $0 <= 70}))
        XCTAssert(secondParent.genes[70...119].allSatisfy({ $0 > 70}))

        XCTAssertFalse(firstParent.genes.elementsEqual(secondParent.genes))
    }
    
    func testInitialPopulationManyHomogeneityCriteria() {
        struct TestStudent: Student {
            
            let id: UInt8
            let knowsSwift: Bool
            let knowsObjc: Bool
            
            init(id: UInt8, knowsSwift: Bool, knowsObjc: Bool) {
                self.id = id
                self.knowsSwift = knowsSwift
                self.knowsObjc = knowsObjc
            }
        }
        
        let students = (1...120).map({ TestStudent(id: $0, knowsSwift: ($0 % 2) == 0, knowsObjc: ($0 <= 60) )})
        let configuration = Configuration(populationSize: 20, mutationProbability: 0.5, maxGenerations: 50, parentCount: 10, maxNumberPermutation: 3)
        let grouping = Grouping(students: students.shuffled(),
                                heterogeneousFactors: nil,
                                homogeneousFactors: [\TestStudent.knowsObjc: 1, \TestStudent.knowsSwift: 1],
                                groupSize: 3,
                                configuration: configuration)
        
        let parent = grouping.makeInitialPopulation(count: 1)[0]
       
        XCTAssert(parent.genes[0...29].allSatisfy({ $0 <= 60 && ($0 % 2) == 0 }))
        
        // Apparently the order of the function array is unstable. Can be 11, 10, 01, 00 or 11, 01, 10, 00
        if (parent.genes[30] <= 60 && (parent.genes[30] % 2) != 0) {
            XCTAssert(parent.genes[30...59].allSatisfy({ $0 <= 60 && ($0 % 2) != 0 }))
            XCTAssert(parent.genes[60...89].allSatisfy({ $0 > 60 && ($0 % 2) == 0 }))
        } else {
            XCTAssert(parent.genes[30...59].allSatisfy({ $0 > 60 && ($0 % 2) == 0 }))
            XCTAssert(parent.genes[60...89].allSatisfy({ $0 <= 60 && ($0 % 2) != 0 }))
        }
        XCTAssert(parent.genes[90...119].allSatisfy({ $0 > 60 && ($0 % 2) != 0 }))
    }
    
    static var allTests = [
        ("testInsertionMutation", testInsertionMutation),
        ("testBasicSolver", testBasicSolver),
        ("testCrossover", testCrossover),
        ("testGrouping", testGrouping),
        ("testRotation", testRotation),
    ]
}
