//
//  Message.swift
//  flutter_xmpp
//
//  Modernized Swift 5+ / Codable + Flutter-ready
//

import Foundation
import XMPPFramework

class Message: Codable {
    
    var id: String = ""
    var jid: String = ""
    var message: String = ""
    var senderJid: String = ""
    var time: String = "0"
    
    // MARK: - Keys for dictionary (optional, Codable handles most)
    private enum CodingKeys: String, CodingKey {
        case id, jid, message, senderJid, time
    }
    
    // MARK: - Initializers
    init() {}
    
    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.jid = data["jid"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.senderJid = data["senderJid"] as? String ?? ""
        self.time = data["time"] as? String ?? self.time
    }
    
    init(fromXMPPMessage message: XMPPMessage) {
        self.id = (message.elementID ?? "").trim()
        self.senderJid = (message.fromStr ?? "").trim()
        self.jid = (message.toStr ?? "").trim()
        self.message = message.elements(forName: xmppConstants.BODY.lowercased())
            .first?.stringValue?.trim() ?? ""
        self.time = message.getTimeElementInfo()
    }
    
    // MARK: - Convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "jid": jid,
            "message": message,
            "senderJid": senderJid,
            "time": time
        ]
    }
}

// MARK: - XMPPMessage Extension for timestamp
extension XMPPMessage {
    func getTimeElementInfo() -> String {
        // Check <delay> element
        if let delay = self.element(forName: "delay", xmlns: "urn:xmpp:delay"),
           let stamp = delay.attributeStringValue(forName: "stamp"),
           !stamp.trim().isEmpty {
            return stamp.trim()
        }
        
        // Check custom <time> element
        if let timeElem = self.element(forName: "time", xmlns: "urn:xmpp:time"),
           let timeValue = timeElem.stringValue,
           !timeValue.trim().isEmpty {
            return timeValue.trim()
        }
        
        // Fallback to current timestamp in milliseconds
        return "\(Int(Date().timeIntervalSince1970 * 1000))"
    }
}

// MARK: - String Extension
fileprivate extension String {
    func trim() -> String { self.trimmingCharacters(in: .whitespacesAndNewlines) }
}
