//
//  utilityFunctions.swift
//  xmpp_plugin
//
//  Modernized for Swift 5 / Xcode 15 / Flutter
//

import Foundation
import Flutter

// MARK: - Notification Observers
public func postNotification(
    name: Notification.Name,
    object: Any? = nil,
    userInfo: [AnyHashable: Any]? = nil
) {
    NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
}

// MARK: - Timestamp Utilities
public func getTimeStamp() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1000)
}

public func getCurrentTime() -> String {
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS" // milliseconds
    dateFormat.locale = Locale(identifier: "en_US_POSIX")
    dateFormat.timeZone = TimeZone.current
    return dateFormat.string(from: Date())
}

// MARK: - Logging Helpers
func printLog<T>(_ message: T) {
    #if DEBUG
    print(message)
    #endif
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
    
    // Add logger to file
    guard let objLogger = APP_DELEGATE.objXMPPLogger else {
        printLog("\(#function) | XMPPLogger not initialized")
        return
    }
    
    guard objLogger.isLogEnable else {
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
        DispatchQueue.global(qos: .background).async {
            writeLogFile(withMessage: message)
        }
    }
    
    private static func writeLogFile(withMessage message: String) {
        guard let logFile = logFile,
              let data = (message + "\n").data(using: .utf8) else { return }
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                defer { try? fileHandle.close() }
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
