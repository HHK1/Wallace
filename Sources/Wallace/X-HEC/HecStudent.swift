//
//  HecStudent.swift
//  Surge
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore

enum Mineur: String, Codable {
    case DeepTech = "Deep Tech"
    case HighTouch = "High Touch"
}
        
struct HECStudent: Student, Codable {
    let id: UInt8
    let firstName: String
    let lastName: String
    let isAGirl: Bool
    
    let isFromHEC: Bool
    let isFromPolytechnique: Bool
    let isFromOther: Bool
    
    let isBusiness: Bool
    let isEngineer: Bool
    let isOther: Bool
    
    let isC2: Bool
    let mineur: Mineur
    
    var studentsMet: Array<Bool>
    
    var juraGroup: Int?
    var creaGroup: Int?
    var scaleUpGroup: Int?
    var redressementGroup: Int?
    
    init(id: UInt8, row: [String], numberOfStudents: Int) {
        self.id = id
        self.firstName = row[1].trimmingCharacters(in: CharacterSet.init(charactersIn: " "))
        self.lastName = row[0].trimmingCharacters(in: CharacterSet.init(charactersIn: " "))
        self.isAGirl = row[2] == "F"
        
        let recruitement = row[3]
        self.isFromHEC = recruitement == "HEC GE"
        self.isFromPolytechnique = recruitement == "X"
        self.isFromOther = recruitement == "MSc"
            
        let category = row[4]
        
        self.isBusiness = category == "Business"
        self.isEngineer = category == "Engineer"
        self.isOther = category == "Other"
        
        self.isC2 = row[5] == "C2 Proficient (mother tongue)"
        self.mineur = Mineur(rawValue: row[6])!
        self.studentsMet = Array<Bool>(repeating: false, count: numberOfStudents)
    }
    
    static var verificationPaths: [KeyPath<HECStudent, Bool>] {
        return [\.isAGirl, \.isFromHEC, \.isFromPolytechnique, \.isFromOther, \.isBusiness, \.isEngineer, \.isOther, \.isC2]
    }
    
    func makeAttributeVector(factors: [Float]) -> Vector {
        let paths = HECStudent.verificationPaths
        assert(factors.count == paths.count, "Provide a factor for each dimension")
        var vector = zip(paths, factors).map { (path, factor) -> Float in
            factor * (self[keyPath: path] ? 1 : 0)
        }
        
        let minorDimension: Float = self.mineur == Mineur.DeepTech ? 1.0 : 0
        vector.append(minorDimension)
        vector.append(contentsOf: studentsMet.map({ $0 == true ? 5.0 : 0 }))
        return vector
    }
    
    var description: String {
        var type = ""
        var recruitement = ""
        if self.isFromPolytechnique {
            recruitement = "X"
        } else if self.isFromHEC {
            recruitement = "HEC GE"
        } else if self.isFromOther {
            recruitement = "MSc"
        }
        
        if self.isEngineer {
            type = "Engineer"
        } else if self.isBusiness {
            type = "Business"
        } else if self.isOther {
            type = "Other"
        }
        
        let gender = self.isAGirl ? "F" : "M"
        let frenchSpeaker = self.isC2 ? "C2" : "Not C2"
        let juraGroupDesc = juraGroup != nil ? "\(juraGroup! + 1)" : "?"
        let creaGroupDesc = creaGroup != nil ? "\(creaGroup! + 1)" : "?"
        let scaleUpGroupDesc = scaleUpGroup != nil ? "\(scaleUpGroup! + 1)" : "?"
        let redressementGroupDesc = redressementGroup != nil ? "\(redressementGroup! + 1)" : "?"

        return "\(self.firstName), \(self.lastName), \(gender), \(recruitement), \(type), \(frenchSpeaker), \(self.mineur.rawValue), \(juraGroupDesc), \(creaGroupDesc), \(scaleUpGroupDesc), \(redressementGroupDesc)"
    }
    
    var shortDescription: String {
        return "\(self.firstName) \(self.lastName)"
    }
    
    static var csvTitle: String {
        return "First Name, Last Name, Gender, Recruitement, Category, French Speaker, Mineur, Groupe Jura, Groupe Créa, Groupe Scale Up, Groupe Redressement \n"
    }
    
    /*
     Based on which groups have already been set, compute the number of the **current** session. So if no groups have been
     set, the session number is the one for Jura, so 1
     */
    var sessionNumber: Int {
        if self.juraGroup == nil {
            return 1
        } else if self.creaGroup == nil {
            return 2
        } else if self.scaleUpGroup == nil {
            return 3
        } else if self.redressementGroup == nil {
            return 4
        } else {
            return -1
        }
    }
}

struct StudentName: Codable {
    let firstName:  String
    let LastName: String
}

extension HECStudent {
    
    func hasMetEnoughStudents(groupSize: Int) -> Bool {
        let expectedStudentMet = sessionNumber * (groupSize - 1)
        let numberOfStudentsMet = self.studentsMet.filter({ $0 == true }).count
        return expectedStudentMet == numberOfStudentsMet
    }
    
    static func isSolutionValid(students: Array<Self>, groups: [Array<Self>]) -> Bool {
        guard let groupSize = groups.first?.count else { return false }
        let areGroupsValid = HECStudent.areGroupsValid(students: students, groups: groups)
        let newStudents = HECStudent.updateStudentsMet(groups: groups)
        let invalidStudents = newStudents.filter({ !$0.hasMetEnoughStudents(groupSize: groupSize) })
        let areGroupsDifferent = invalidStudents.isEmpty
        return areGroupsValid && areGroupsDifferent
    }
    
    static func updateStudentsMet(groups: [Array<HECStudent>]) -> [HECStudent] {

        return groups.enumerated().reduce([], { (newStudents, entry) -> [HECStudent] in
            let (_, group) = entry
           
            let groupStudents = group.map { (student) -> HECStudent in
                var studentCopy = student
                var updatedStudentsMet = studentCopy.studentsMet
                group.filter({ $0.id != student.id }).forEach({ updatedStudentsMet[Int($0.id)] = true })
                studentCopy.studentsMet = updatedStudentsMet
                return studentCopy
            }
            var next = newStudents
            next.append(contentsOf: groupStudents)
            return next
        })
    }
}

