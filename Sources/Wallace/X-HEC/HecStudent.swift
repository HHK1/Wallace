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
    let hasACar: Bool
    let isFromHEC: Bool
    let isFromPolytechnique: Bool
    let isFromOther: Bool
    let mineur: Mineur
    
    var juraGroups: Vector?
    var creaGroups: Vector?
    var redressementGroups: Vector?
    
    init(id: UInt8, row: [String]) {
        self.id = id
        self.firstName = row[0]
        self.lastName = row[1]
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
        if let juraGroups = juraGroups {
            vector.append(contentsOf: juraGroups)
        }
        if let creaGroups = creaGroups {
            vector.append(contentsOf: creaGroups)
        }
        if let redressementGroups = redressementGroups {
            vector.append(contentsOf: redressementGroups)
        }
        return vector
    }
    
    var description: String {
        var type = ""
        if self.isFromPolytechnique {
            type = "X"
        } else if self.isFromHEC {
            type = "HEC"
        } else if self.isFromOther {
            type = "Divers"
        }
        let gender = self.isAGirl ? "Girl" : "Boy"
        return "\(self.firstName) \(self.lastName): \(type), \(gender)"
    }
}

struct StudentName: Codable {
    
    let firstName:  String
    let LastName: String
}
