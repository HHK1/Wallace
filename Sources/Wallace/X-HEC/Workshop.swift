//
//  Workshop.swift
//  
//
//  Created by Henry Huck on 20/08/2021.
//

import Foundation
import ArgumentParser

enum EncodedFactor: String, Codable, ExpressibleByArgument {
    case gender
    case school
    case type
    case frenchSpeaker
    
    func makeFactors(multiplier: Int) ->  [KeyPath<HECStudent, Bool> : Int] {
        switch self {
        case .gender:
            return [\HECStudent.isAGirl: multiplier]
        case .school:
            return [\HECStudent.isGE: multiplier, \HECStudent.isMsc: multiplier]
        case .type:
            return [\HECStudent.isBusiness: multiplier, \HECStudent.isEngineer: multiplier, \HECStudent.isOther: multiplier]
        case .frenchSpeaker:
            return [\HECStudent.isFrench: multiplier]
        
        }
    }
    
    static var allFactors: Dictionary<EncodedFactor, Int> {
        return [.gender: 10, .school: 10, .type: 10, .frenchSpeaker: 10]
    }
}

struct Workshop: Codable, CustomStringConvertible {
    
    let name: String
    let groupSize: Int
    let rawHeterogeneousFactors: Dictionary<EncodedFactor, Int>
    let rawHomogeneousFactors: Dictionary<EncodedFactor, Int>?
    let hikeConfiguration: HikeConfiguration?
    
    var heterogeneousFactors: [KeyPath<HECStudent, Bool> : Int] {
        return makeFactors(rawFactors: rawHeterogeneousFactors)
    }
    
    var homogeneousFactors: [KeyPath<HECStudent, Bool> : Int]? {
        guard let rawFactors = rawHomogeneousFactors else {
            return nil
        }
        return makeFactors(rawFactors: rawFactors)
    }
    
    var fileName: String {
        return "\(name).txt"
    }

    private func makeFactors(rawFactors: Dictionary<EncodedFactor, Int>) -> [KeyPath<HECStudent, Bool> : Int] {
        let initialValue: [KeyPath<HECStudent, Bool> : Int] = [:]
        return rawFactors.keys.reduce(initialValue) { (partialResult, encodedFactor) in
            let decodedFactors = encodedFactor.makeFactors(multiplier: rawFactors[encodedFactor]!)
            return partialResult.merging(decodedFactors, uniquingKeysWith: { (current, _) in current })
        }
    }
    
    var description: String {
        var factorsDesc = self.rawHeterogeneousFactors.keys.map({ "\($0): \(self.rawHeterogeneousFactors[$0]!)" })
        let heteroDesc = " - Heterogeneous factors: \n    • \(factorsDesc.joined(separator: "\n    • "))\n"
        var homoDesc: String = ""
        if let rawHomogeneousFactors = rawHomogeneousFactors, !rawHomogeneousFactors.isEmpty {
            factorsDesc = rawHomogeneousFactors.keys.map({ "\($0): \(rawHomogeneousFactors[$0]!)" })
            homoDesc = " - Homogeneous factors: \n    • \(factorsDesc.joined(separator: "\n    • "))\n"
        }
        let hikeDesc = hikeConfiguration != nil ? " - Hike configuration: \n\(hikeConfiguration!.description)" : ""
        return "Name: \(self.name)\n - Group size: \(groupSize)\n\(heteroDesc)\(homoDesc)\(hikeDesc)"
    }
    
   
    static var allValues: Array<Workshop> = load()
    
    private static func load() -> Array<Workshop> {
        do {
            let decoder = JSONDecoder()
            let data = try Data(contentsOf: URL(fileURLWithPath: "workshops.json"))
            return try decoder.decode(Array<Workshop>.self, from: data)
        } catch (let error) {
            logWarning("Error initializing worshops, \(error.localizedDescription)")
            return []
        }
    }
    
    static func save() throws {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(allValues)
        try writeToFile(data: encoded, path: "workshops.json")
    }
    
    static func getWorkshop(name: String) throws -> Workshop {
        guard let workshop = allValues.first(where: { $0.name == name }) else {
            throw CLIException.invalidWorkshopName
        }
        return workshop
    }
}

/**
    Configuration for the "groupes de marche" after the Jura workshop.
 */
struct HikeConfiguration: Codable, CustomStringConvertible {
    /** Size of each group. In that case a group is a group of groups of students. */
    var groupSize: Int
    /** Basically the number of hike days */
    var numberOfRotations: Int
    
    var description: String {
        return "    • Group size: \(self.groupSize)\n    • Number of rotations: \(numberOfRotations)"
    }
}

