//
//  Message.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

class Message {
    var id: String = ""
    var jid: String = ""
    var message: String = ""
    var senderJid: String = ""
    var time: String = "0"
    
    // MARK: - Keys for dictionary representation
    private struct Keys {
        static let id = "id"
        static let jid = "jid"
        static let message = "message"
        static let senderJid = "senderJid"
        static let time = "time"
    }
    
    // MARK: - Initializers
    init() {}
    
    init(data: [String: Any]) {
        self.id = data[Keys.id] as? String ?? ""
        self.jid = data[Keys.jid] as? String ?? ""
        self.message = data[Keys.message] as? String ?? ""
        self.senderJid = data[Keys.senderJid] as? String ?? ""
        self.time = data[Keys.time] as? String ?? self.time
    }
    
    // MARK: - Convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            Keys.id: id,
            Keys.jid: jid,
            Keys.message: message,
            Keys.senderJid: senderJid,
            Keys.time: time
        ]
    }
    
    // MARK: - Initialize from XMPPMessage
    func initWithMessage(_ message: XMPPMessage) {
        self.setSenderAndReceiver(from: message)
        self.setText(from: message)
        self.time = message.getTimeElementInfo()
    }
    
    // MARK: - Sender and receiver
    private func setSenderAndReceiver(from message: XMPPMessage) {
        self.id = (message.elementID ?? "").trim()
        
        let type = message.type ?? ""
        switch type {
        case xmppChatType.GROUPCHAT, xmppChatType.CHAT:
            self.senderJid = (message.fromStr ?? "").trim()
            self.jid = (message.toStr ?? "").trim()
        default:
            self.senderJid = (message.fromStr ?? "").trim()
            self.jid = (message.toStr ?? "").trim()
        }
    }
    
    // MARK: - Message body
    private func setText(from message: XMPPMessage) {
        if let body = message.elements(forName: xmppConstants.BODY.lowercased())
            .first?
            .stringValue {
            self.message = body.trim()
        } else {
            self.message = ""
        }
    }
}
