//
//  Workshop.swift
//  
//
//  Created by Henry Huck on 20/08/2021.
//

import Foundation

private let defaultFactors = [
    \HECStudent.isAGirl: 1,
    \HECStudent.isFromHEC: 1,
    \HECStudent.isFromPolytechnique: 1,
    \HECStudent.isFromOther: 1,
    \HECStudent.isBusiness: 1,
    \HECStudent.isEngineer: 1,
    \HECStudent.isOther: 1,
    \HECStudent.isC2: 1,
    \HECStudent.isDeepTech: 1
]

enum Workshop: String, Codable, CaseIterable {
    
    case jura
    case crea
    case scaleUp
    case redressement
    
    static var promoSize: Int = 0
    
    var groupSize: Int {
        switch self {
        case .jura:
            return 3
        case .crea:
            return 3
        case .scaleUp:
            return 4
        case .redressement:
            return 4
        }
    }
    
    var fileName: String  {
        switch self {
        case .jura:
            return "jura.txt"
        case .crea:
            return "crea.txt"
        case .scaleUp:
            return "scaleUp.txt"
        case .redressement:
            return "redressement.txt"
        }
    }
    
    var heterogeneousFactors: Dictionary<KeyPath<HECStudent, Bool>, Int> {
        switch self {
        case .crea:
            var factors = defaultFactors
            factors.remove(at: factors.index(forKey: \HECStudent.isDeepTech)!)
            return factors
        default:
            return defaultFactors
        }
    }
    
    var homogeneousFactors: Dictionary<KeyPath<HECStudent, Bool>, Int>? {
        switch self {
        case .crea:
            return [\HECStudent.isDeepTech: 1]
        default:
            return nil
        }
    }
}

struct HikeJura {
    static var groupSize: Int = 4
    static var numberOfRotations: Int = 4
}
