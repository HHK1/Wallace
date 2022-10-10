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
    
    
    var groups: Dictionary<String, Int> = Dictionary()
    // Internal representation of students met. Easier to work with for exports, as each workshop can be resetted
    // For vector manipulation or verification, the studentsMet contain all the students.
    var studentsMetByWorshop: Dictionary<String, Array<UInt8>> = Dictionary()
    
    /**
     The hike groups for Jura. Each element is a hike day, and each value represents the "meta" group number.
    */
    var hikeGroups: Dictionary<Int, Int?> = Dictionary() 

    var studentsMet: Array<UInt8> {
        return studentsMetByWorshop.values.reduce(into: []) { (all, workshop) in
            return all.append(contentsOf: workshop)
        }
    }
    
    /**
     Number of the first group. Historically groups started prefixed with 100
     */
    static var groupOffset: Int = 101
    
    
    init(id: UInt8, row: [String]) {
        self.id = id
        self.firstName = row[1].trim()
        self.lastName = row[0].trim()
        self.isAGirl = row[2].trim() == "F"
        
        let recruitement = row[3].trim()
        self.isFromHEC = recruitement == "HEC GE"
        self.isFromPolytechnique = recruitement == "X"
        self.isFromOther = recruitement == "MSc"
            
        let category = row[4].trim()
        
        self.isBusiness = category == "Business"
        self.isEngineer = category == "Engineer"
        self.isOther = category == "Other"
        
        self.isC2 = row[5].trim() == "C2"
        self.isDeepTech = row[6].trim() == Mineur.deepTech.rawValue
    }
    
    func makeHeterogeneousAttributeVector(factors: Factors<HECStudent>) -> Vector {
        var vector: Vector = factors.keys.map({ self[keyPath: $0] ? Float(factors[$0]!) : 0 })
        var studentsMetVector = Array<Float>(repeating: 0.0, count: HECStudent.students.count)
        self.studentsMet.forEach({ studentsMetVector[Int($0)] = 1.0 })
        vector.append(contentsOf: studentsMetVector)
        return vector
    }
    
    func makeHomogenenousAttributeVector(factors: Factors<HECStudent>) -> Vector {
        return factors.keys.map({ self[keyPath: $0] ? Float(factors[$0]!) : 0 })
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
        
        var components: Array<String> = ["\(id)", firstName, lastName, gender, recruitement, type, frenchSpeaker, mineur]

        // Historically the group numbers start at 100
        let workshopDesc = Workshop.allValues.map({ groups[$0.name] == nil ? "?" : "\(groups[$0.name]! + HECStudent.groupOffset)"})
        let juraHikeGroupsDesc = hikeGroups.keys.sorted().map({ "\(hikeGroups[$0]??.description ?? "?")" })
        
        components.append(contentsOf: workshopDesc)
        components.append(contentsOf: juraHikeGroupsDesc)

        return components.joined(separator: ";")
    }
    
    var shortDescription: String {
        return "\(self.firstName) \(self.lastName)"
    }
    
    static var csvTitle: String {
        return ["Id", "First Name", "Last Name", "Gender", "Recruitement", "Category", "French Speaker","Mineur", "Groupe Jura",  "Groupe Créa", "Groupe Scale Up", "Groupe Redressement", "Groupe Marche Jura Jour 1", "Groupe Marche Jura Jour 2", "Groupe Marche Jura Jour 3", "Groupe Marche Jura Jour 4"].joined(separator: ";") + "\n"
    }
    
    static var students: Array<HECStudent> = load()
    
    private static func load() -> Array<HECStudent> {
        do {
            let decoder = JSONDecoder()
            let data = try Data(contentsOf: URL(fileURLWithPath: "students.json"))
            return try decoder.decode(Array<HECStudent>.self, from: data)
        } catch (let error) {
            logWarning("Error initializing students, \(error)")
            return []
        }
    }
    
    static func save() throws {
        try encodeStudents(students: HECStudent.students)
    }
    
    static func == (lhs: HECStudent, rhs: HECStudent) -> Bool {
        return lhs.id == rhs.id
    }
}

struct StudentName: Codable {
    let firstName:  String
    let LastName: String
}
