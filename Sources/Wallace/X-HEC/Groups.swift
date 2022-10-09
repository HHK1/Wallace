//
//  Groups.swift
//  
//
//  Created by Henry Huck on 09/10/2022.
//

import Foundation

enum GroupError: Error {
    case studentHasGroupMissing
}

/**
 Given students who have their group number set, regenerate the group array for a given workshop.
 */
func getGroups(from students: [HECStudent], for workshop: Workshop) throws -> [[HECStudent]]  {
    let numberOfGroups = Int(ceil(Double(students.count / workshop.groupSize)))
    var groups: [[HECStudent]] = Array.init(repeating: [], count: numberOfGroups)
    groups = try students.reduce(groups) { (result, student) -> [[HECStudent]] in
        var resultCopy = result
        guard let groupNumber = student.groups[workshop] else {
            throw GroupError.studentHasGroupMissing
        }
        resultCopy[groupNumber].append(student)
        return resultCopy
    }
    return groups
}

func updateStudents(with groups: [Array<HECStudent>], for workshop: Workshop) -> [HECStudent] {

    return groups.enumerated().reduce([], { (newStudents, entry) -> [HECStudent] in
        let (index, group) = entry
       
        let groupStudents = group.map { (student) -> HECStudent in
            student.groups[workshop] = index
            student.studentsMetByWorshop[workshop] = group.filter({ $0.id != student.id }).map({ $0.id })
            return student
        }
        var next = newStudents
        next.append(contentsOf: groupStudents)
        return next
    })
}
