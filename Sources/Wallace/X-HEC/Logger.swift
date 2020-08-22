//
//  Logger.swift
//  Wallace
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore

class CLILogger: LoggerDelegate {
    
    var debug: Bool
    static let shared = CLILogger()
    
    init() {
        self.debug = false
        Logger.shared.delegate = self
    }
    
    public func didReceiveLog(log: @autoclosure () -> Any, level: LogLevel) {
          if (level.rawValue > LogLevel.debug.rawValue || debug) {
              print(log())
          }
    }
}
