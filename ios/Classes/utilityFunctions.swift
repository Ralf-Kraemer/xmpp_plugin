//
//  utilityFunctions.swift
//  xmpp_plugin
//
//  Created by xRStudio on 13/12/21.
//

import Foundation
import Flutter

// MARK: - Notification Observers
public func postNotification(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
}

// MARK: - Timestamp Utilities
public func getTimeStamp() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1000)
}

public func getCurrentTime() -> String {
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    return dateFormat.string(from: Date())
}

// MARK: - Logging Helpers
func printLog<T>(_ message: T) {
    print(message)
}

func addLogger(_ logType: LogType, _ value: Any) {
    var logMessage = "Time: \(getCurrentTime())\n"
    logMessage += "Action: \(logType.rawValue)\n"
    
    switch logType {
    case .receiveFromFlutter:
        if let data = value as? FlutterMethodCall {
            logMessage += "NativeMethod: \(data.method)\n"
            logMessage += "Content: \(data.arguments.debugDescription)\n\n"
        }
    default:
        logMessage += "Timestamp: \(getTimeStamp())\n"
        logMessage += "Content: \(value)\n\n"
    }
    
    printLog(logMessage)
    
    // Add Logger in log-file
    guard let objLogger = APP_DELEGATE.objXMPPLogger else {
        printLog("\(#function) | XMPPLogger not initialized")
        return
    }
    
    if !objLogger.isLogEnable {
        printLog("\(#function) | XMPP Logger is disabled.")
        return
    }
    
    AppLogger.log(logMessage)
}

// MARK: - AppLogger
class AppLogger {
    static var logFile: URL? {
        guard let objLogger = APP_DELEGATE.objXMPPLogger else { return nil }
        return URL(fileURLWithPath: objLogger.logPath)
    }
    
    static func log(_ message: String) {
        writeLogFile(withMessage: message)
    }
    
    private static func writeLogFile(withMessage message: String) {
        guard let logFile = logFile, let data = (message + "\n").data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            } catch {
                print("\(#function) | Error writing to log file: \(error.localizedDescription) | Path: \(logFile.path)")
            }
        } else {
            do {
                try data.write(to: logFile, options: .atomicWrite)
            } catch {
                print("\(#function) | Error creating log file: \(error.localizedDescription) | Path: \(logFile.path)")
            }
        }
    }
    
    /*
    static func deleteLogFile() {
        guard let logFile = logFile else { return }
        guard FileManager.default.fileExists(atPath: logFile.path) else { return }
        try? FileManager.default.removeItem(at: logFile)
    }
    */
}
