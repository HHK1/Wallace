//
//  HecStudent.swift
//  Wallace
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore

enum Mineur: String {
    case deepTech = "Deep Tech"
    case highTouch = "High Touch"
}
        
final class HECStudent: Student, Codable {
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
    let isDeepTech: Bool
    
    
    var groups: Dictionary<Workshop, Int> = Dictionary()
    // Internal representation of students met. Easier to work with for exports, as each workshop can be resetted
    // For vector manipulation or verification, the studentsMet contain all the students.
    var studentsMetByWorshop: Dictionary<Workshop, Array<UInt8>> = Dictionary()
    
    // TODO: students should also hold the hike groups

    var studentsMet: Array<UInt8> {
        return studentsMetByWorshop.values.reduce(into: []) { (all, workshop) in
            return all.append(contentsOf: workshop)
        }
    }
    
    static var promoSize: Int = 120
    
    
    init(id: UInt8, row: [String]) {
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
        self.isDeepTech = row[6] == Mineur.deepTech.rawValue
    }
    
    func makeHeterogeneousAttributeVector(factors: Factors<HECStudent>) -> Vector {
        var vector: Vector = factors.keys.map({ self[keyPath: $0] ? 1 : 0 })
        var studentsMetVector = Array<Float>(repeating: 0.0, count: HECStudent.promoSize)
        self.studentsMet.forEach({ studentsMetVector[Int($0)] = 5.0 })
        vector.append(contentsOf: studentsMetVector)
        return vector
    }
    
    func makeHomogenenousAttributeVector(factors: Factors<HECStudent>) -> Vector {
        return factors.keys.map({ self[keyPath: $0] ? 1 : 0 })
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
        let mineur = self.isDeepTech ? Mineur.deepTech.rawValue : Mineur.highTouch.rawValue
        let frenchSpeaker = self.isC2 ? "C2" : "Not C2"
        
        // Historically the group numbers start at 100
        let juraGroupDesc = groups[.jura] != nil ? "\(groups[.jura]! + 101)" : "?"
        let creaGroupDesc = groups[.crea] != nil ? "\(groups[.crea]! + 101)" : "?"
        let scaleUpGroupDesc = groups[.scaleUp] != nil ? "\(groups[.scaleUp]! + 101)" : "?"
        let redressementGroupDesc = groups[.redressement] != nil ? "\(groups[.redressement]! + 101)" : "?"

        return "\(self.id), \(self.firstName), \(self.lastName), \(gender), \(recruitement), \(type), \(frenchSpeaker), \(mineur), \(juraGroupDesc), \(creaGroupDesc), \(scaleUpGroupDesc), \(redressementGroupDesc)"
    }
    
    
    var shortDescription: String {
        return "\(self.firstName) \(self.lastName)"
    }
    
    static var csvTitle: String {
        return "Id, First Name, Last Name, Gender, Recruitement, Category, French Speaker, Mineur, Groupe Jura,  Groupe Créa, Groupe Scale Up, Groupe Redressement \n"
    }
}

struct StudentName: Codable {
    let firstName:  String
    let LastName: String
}
