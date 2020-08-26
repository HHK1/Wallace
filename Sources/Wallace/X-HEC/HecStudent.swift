//
//  HecStudent.swift
//  Surge
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore

enum Mineur: String, Codable {
    case DeepTech = "deep tech"
    case HighTouch = "high touch"
}
        
struct HECStudent: Student, Codable {
    let id: UInt8
    let firstName: String
    let lastName: String
    let isAGirl: Bool
    let hasACar: Bool
    let isFromHEC: Bool
    let isFromPolytechnique: Bool
    let isFromOther: Bool
    let mineur: Mineur
    
    var juraGroups: Vector?
    var creaGroups: Vector?
    var redressementGroups: Vector?
    var scaleUpGroups: Vector?
    
    init(id: UInt8, row: [String]) {
        self.id = id
        self.firstName = row[0].trimmingCharacters(in: CharacterSet.init(charactersIn: " "))
        self.lastName = row[1].trimmingCharacters(in: CharacterSet.init(charactersIn: " "))
        self.isAGirl = Bool(row[2])!
        self.hasACar = false
        self.isFromHEC = Bool(row[3])!
        self.isFromOther = Bool(row[4])!
        self.isFromPolytechnique = Bool(row[5])!
        self.mineur = Mineur(rawValue: row[6])!
    }
    
    func makeAttributeVector(factors: [Float]) -> Vector {
        let paths: [KeyPath<HECStudent, Bool>]  = [\.isAGirl, \.hasACar, \.isFromHEC, \.isFromPolytechnique, \.isFromOther]
        assert(factors.count == paths.count, "Provide a factor for each dimension")
        var vector = zip(paths, factors).map { (path, factor) -> Float in
            factor * (self[keyPath: path] ? 1 : 0)
        }
        
        let minorDimension: Float = self.mineur == Mineur.DeepTech ? 0.9 : 0
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
    
    var description: String {
        var type = ""
        if self.isFromPolytechnique {
            type = "Ingénieur"
        } else if self.isFromHEC {
            type = "Commerce"
        } else if self.isFromOther {
            type = "Autres"
        }
        let gender = self.isAGirl ? "Fille" : "Garçon"
        let juraGroup = self.juraGroups!.firstIndex(of: 1.0)!
        let creaGroup = self.creaGroups!.firstIndex(of: 1.0)!
        let scaleUpGroup = self.scaleUpGroups!.firstIndex(of: 1.0)!
        let redressementgroup = self.redressementGroups!.firstIndex(of: 1.0)!
        return "\(self.firstName) \(self.lastName); \(gender); \(type); \(self.mineur.rawValue); \(juraGroup); \(creaGroup); \(scaleUpGroup); \(redressementgroup)"
    }
    
    var shortDescription: String {
        return "\(self.firstName) \(self.lastName)"
    }
        
}

struct StudentName: Codable {
    
    let firstName:  String
    let LastName: String
}
