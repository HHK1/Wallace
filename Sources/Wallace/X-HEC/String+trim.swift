//
//  File.swift
//  
//
//  Created by Henry Huck on 09/10/2022.
//

import Foundation

extension String {
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.init(charactersIn: " "))
    }
}
