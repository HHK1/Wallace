//
//  Logger.swift
//  WallaceCore
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation

public enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warning
    case error
    
    public var emoji: String {
        switch self {
        case .verbose: return "💜"
        case .debug: return "💙"
        case .info: return "💚"
        case .warning: return "💛"
        case .error: return "❤️"
        }
    }
}

public protocol LoggerDelegate: class {
    func didReceiveLog(log: @autoclosure () -> Any, level: LogLevel)
}

public class Logger {
    public weak var delegate: LoggerDelegate?
    public static let shared = Logger()
    
    private init() { }
}

/// log something generally unimportant (lowest priority)
func logVerbose(_ message: @autoclosure () -> Any, _ file: String = #file,
                      _ function: String = #function, line: Int = #line) {
     
     Logger.shared.delegate?.didReceiveLog(log: message(), level: .verbose)
 }

/// log something which help during debugging (low priority)
func logDebug(_ message: @autoclosure () -> Any, _ file: String = #file,
                     _ function: String = #function, line: Int = #line) {
    
    Logger.shared.delegate?.didReceiveLog(log: message(), level: .debug)
}

/// log something which you are really interested but which is not an issue or error (normal priority)
public func logInfo(_ message: @autoclosure () -> Any, _ file: String = #file,
                    _ function: String = #function, line: Int = #line) {
    
    Logger.shared.delegate?.didReceiveLog(log: message(), level: .info)
}

/// log something which may cause big trouble soon (high priority)
public func logWarning(_ message: @autoclosure () -> Any, _ file: String = #file,
                       _ function: String = #function, line: Int = #line) {

    Logger.shared.delegate?.didReceiveLog(log: message(), level: .warning)
}

/// log something which will keep you awake at night (highest priority)
public func logError(_ message: @autoclosure () -> Any, _ file: String = #file,
                     _ function: String = #function, line: Int = #line) {

    Logger.shared.delegate?.didReceiveLog(log: message(), level: .error)
}
