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
    
    var juraGroups: Vector?
    var creaGroups: Vector?
    var redressementGroups: Vector?
    var scaleUpGroups: Vector?
    
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
        self.mineur = Mineur(rawValue: row[6])!
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
        
        if let juraGroups = juraGroups {
            vector.append(contentsOf: juraGroups)
        }
        if let creaGroups = creaGroups {
            vector.append(contentsOf: creaGroups)
        }
        if let scaleUpGroups = scaleUpGroups {
            vector.append(contentsOf: scaleUpGroups)
        }
        return vector
    }
    
    var juraGroup: Int? {
       return self.juraGroups?.firstIndex(of: 1.0)
    }
    
    var creaGroup: Int? {
       return self.creaGroups?.firstIndex(of: 1.0)
    }
    
    var scaleUpGroup: Int? {
       return self.scaleUpGroups?.firstIndex(of: 1.0)
    }
    
    var redressementGroup: Int? {
        return self.redressementGroups?.firstIndex(of: 1.0)
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
}

struct StudentName: Codable {
    
    let firstName:  String
    let LastName: String
}


