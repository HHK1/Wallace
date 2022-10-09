//
//  Logger.swift
//  Wallace
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore


class CLILogger: LoggerDelegate {
    
    var logLevel: LogLevel
    static let shared = CLILogger()
    
    init(level: LogLevel = LogLevel.info) {
        self.logLevel = level
        Logger.shared.delegate = self
    }
    
    func log(log: @autoclosure () -> Any, level: LogLevel) {
        if (level.rawValue >= self.logLevel.rawValue) {
            print("\(level.emoji) \(log())")
        }
    }
    
    public func didReceiveLog(log: @autoclosure () -> Any, level: WallaceCore.LogLevel) {
        self.log(log: log(), level: level)
    }
}

/// log something generally unimportant (lowest priority)
func logVerbose(_ message: @autoclosure () -> Any, _ file: String = #file,
                      _ function: String = #function, line: Int = #line) {
     
    CLILogger.shared.log(log: message(), level: .verbose)
 }

/// log something which help during debugging (low priority)
func logDebug(_ message: @autoclosure () -> Any, _ file: String = #file,
                     _ function: String = #function, line: Int = #line) {
    
    CLILogger.shared.log(log: message(), level: .debug)
}

/// log something which you are really interested but which is not an issue or error (normal priority)
public func logInfo(_ message: @autoclosure () -> Any, _ file: String = #file,
                    _ function: String = #function, line: Int = #line) {
    
    CLILogger.shared.log(log: message(), level: .info)
}

/// log something which may cause big trouble soon (high priority)
public func logWarning(_ message: @autoclosure () -> Any, _ file: String = #file,
                       _ function: String = #function, line: Int = #line) {

    CLILogger.shared.log(log: message(), level: .warning)
}

/// log something which will keep you awake at night (highest priority)
public func logError(_ message: @autoclosure () -> Any, _ file: String = #file,
                     _ function: String = #function, line: Int = #line) {

    CLILogger.shared.log(log: message(), level: .error)
}
