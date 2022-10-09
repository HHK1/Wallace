//
//  Verifier.swift
//  
//
//  Created by Henry Huck on 20/08/2021.
//

import Foundation
import WallaceCore
    
    /** A solution is valid if:
        - All student are not meeting other student with the same value for heterogenous factors
        - Requirements for homogeneous factors are met
        - No student has met another student twice.
    */
    func isSolutionValid(groups: [[HECStudent]], workshop: Workshop) -> Bool {
        let areGroupsValid = Verifier.areGroupsValid(groups: groups,
                                                     heterogeneousFactors: workshop.heterogeneousFactors,
                                                     homogeneousFactors: workshop.homogeneousFactors)
        let metNewStudents = hasMetOnlyNewStudents(groups: groups)
        
        logDebug("Verified result, valid: \(areGroupsValid), only new students met: \(metNewStudents)")
        return areGroupsValid && metNewStudents
    }
       
    private func hasMetOnlyNewStudents(groups: [Array<HECStudent>]) -> Bool {
        for group in groups {
            for student in group {
                var studentAlreadyMet = student.studentsMet
                let newStudentsMet = group.filter({ $0.id != student.id }).map({ $0.id })
                studentAlreadyMet.append(contentsOf: newStudentsMet)
                let updatedStudentsMet = Set(studentAlreadyMet)
                if (updatedStudentsMet.count != student.studentsMet.count + newStudentsMet.count) {
                    return false
                }
            }
        }
        return true
    }

