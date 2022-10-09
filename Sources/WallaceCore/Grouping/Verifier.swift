//
//  Verifier.swift
//  
//
//  Created by Henry Huck on 20/08/2021.
//

import Foundation

public typealias Verification<T: Student> = (_: [[T]]) -> Bool

public struct Verifier {
    
    public static func areGroupsValid<T: Student>(groups: [Array<T>], heterogeneousFactors: Factors<T>? = nil,
                                           homogeneousFactors: Factors<T>? = nil) -> Bool {
        
        guard let homogeneousFactors = homogeneousFactors else {
            return areGroupsHeterogeneous(groups: groups, factors: heterogeneousFactors)
        }
        
        for keyPath in homogeneousFactors.keys {
            let result = splitHomogenousGroups(groups: groups, path: keyPath)
            
            guard let (trueGroups, falseGroups) = result else {
                logDebug("Groups are not split homogeneously")
                logVerbose("\(groups.map({ $0.map({ "\($0[keyPath: keyPath])" }).joined(separator: ",") }).joined(separator: "\n"))")
                return false
            }
            if (!areGroupsHeterogeneous(groups: trueGroups, factors: heterogeneousFactors)) {
                logDebug("True group is not heterogeneous")
                return false
            }
            if (!areGroupsHeterogeneous(groups: falseGroups, factors: heterogeneousFactors)) {
                logDebug("False group is not heterogeneous")
                return false
            }
        }
        return true
    }
    
    static func splitHomogenousGroups<T: Student>(groups: [[T]], path: KeyPath<T, Bool>) -> ([[T]], [[T]])? {
        var invalidGroups = 0
        var trueGroups: [[T]] = []
        var falseGroups: [[T]] = []
        
        for group in groups {
            let expectedValue = group.first![keyPath: path]
            let isValid = group.allSatisfy({ $0[keyPath: path] == expectedValue })
            if (!isValid) {
                invalidGroups += 1
                if invalidGroups > 1  {
                    return nil
                }
            }
            if expectedValue == true {
                trueGroups.append(group)
            } else {
                falseGroups.append(group)
            }
        }
        return (trueGroups, falseGroups)
    }
    
    
    public static func areGroupsHeterogeneous<T: Student>(groups: [Array<T>], factors: Factors<T>?) -> Bool {
        guard let groupSize = groups.first?.count else { return false }
        guard let factors = factors else { return true }
        let numberOfGroups = groups.count
        let students = groups.flatMap({ $0 })
        
        let matches = factors.keys.map { (path) -> Bool in
            let numberOfStudents = students.filter({ $0[keyPath: path] == true }).count
            let expectedDistribution = Verifier.groupDistribution(students: numberOfStudents, numberOfGroups: numberOfGroups, groupSize: groupSize)
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

