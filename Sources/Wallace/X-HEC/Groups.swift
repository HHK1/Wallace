//
//  Groups.swift
//  
//
//  Created by Henry Huck on 09/10/2022.
//

import Foundation
import WallaceCore

/**
 Given students who have their group number set, regenerate the group array for a given workshop.
 */
func getGroups(from students: [HECStudent], for workshop: Workshop) throws -> [[HECStudent]]  {
    let numberOfGroups = Int(ceil(Double(students.count / workshop.groupSize)))
    var groups: [[HECStudent]] = Array.init(repeating: [], count: numberOfGroups)
    groups = try students.reduce(groups) { (result, student) -> [[HECStudent]] in
        var resultCopy = result
        guard let groupNumber = student.groups[workshop.name] else {
            throw CLIException.studentHasGroupMissing
        }
        resultCopy[groupNumber].append(student)
        return resultCopy
    }
    return groups
}

/**
    Given groups generated for a workshop, return updated students with the corresponding workshop informations (group ID and students met) properly set.
 */
func updateStudents(with groups: [Array<HECStudent>], for workshop: Workshop) -> [HECStudent] {

    return groups.enumerated().reduce([], { (newStudents, entry) -> [HECStudent] in
        let (index, group) = entry
       
        let groupStudents = group.map { (student) -> HECStudent in
            student.groups[workshop.name] = index
            student.studentsMetByWorshop[workshop.name] = group.filter({ $0.id != student.id }).map({ $0.id })
            return student
        }
        var next = newStudents
        next.append(contentsOf: groupStudents)
        return next
    })
}

func updateStudents(students: [HECStudent], with rotations: [Rotation], groups: Array<[HECStudent]>) -> [HECStudent] {
    rotations.enumerated().forEach({ (rotationIndex, rotation) in
        rotation.enumerated().forEach({ (index, groupOfGroups) in
            let hikeGroupId = index + 1
            groupOfGroups.forEach { (groupId) in
                let groupOfStudents = groups[groupId]
                groupOfStudents.forEach({ $0.hikeGroups[rotationIndex] = hikeGroupId })
            }
        })
    })
    return students
}
