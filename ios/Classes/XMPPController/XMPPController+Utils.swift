//
//  XMPPController+Utils.swift
//  xmpp_plugin
//
//  Modernized for Swift 5 / Xcode 15, fully safe and Flutter-ready.
//

import Foundation
import XMPPFramework

// MARK: - Manage MUCSUB messages
func manage_MucSubMessage(_ message: XMPPMessage) -> XMPPMessage? {
    
    // Only process messages containing a pubsub#event
    guard let _ = message.element(forName: "event", xmlns: "http://jabber.org/protocol/pubsub#event") else {
        return nil
    }
    
    printLog("\(#function) | MUCSub event detected")
    
    // Extract <message> from the nested structure
    guard let nestedMessageXML = message
        .element(forName: "event", xmlns: "http://jabber.org/protocol/pubsub#event")?
        .element(forName: "items")?
        .element(forName: "item")?
        .element(forName: "message")?
        .xmlString else {
            printLog("\(#function) | No nested <message> found")
            return nil
    }
    
    guard let xmppMessage = getXMPPMessage(fromXML: nestedMessageXML) else {
        printLog("\(#function) | Failed to parse nested <message>")
        return nil
    }
    
    // Ensure bare JID (resource-less)
    let bareJID = xmppMessage.from?.bare ?? ""
    printLog("\(#function) | Normalized bareJID: \(bareJID)")
    
    // Ensure timestamp exists — Dart expects non-empty time
    if xmppMessage.element(forName: "delay") == nil {
        let timestamp = xmppMessage.getTimestamp()
        let delayElement = DDXMLElement(name: "delay", stringValue: timestamp)
        xmppMessage.addChild(delayElement)
    }
    
    return xmppMessage
}

// MARK: - XMPPMessage timestamp helper
extension XMPPMessage {
    
    /// Returns a valid timestamp string
    func getTimestamp() -> String {
        // Custom <time> element (if present)
        if let timeElement = self.element(forName: "time", xmlns: "urn:xmpp:time"),
           let timeValue = timeElement.stringValue?.trim(), !timeValue.isEmpty {
            return timeValue
        }
        
        // XEP-0203 <delay> element
        if let delayElement = self.element(forName: "delay", xmlns: "urn:xmpp:delay"),
           let delayStamp = delayElement.attributeStringValue(forName: "stamp")?.trim(),
           !delayStamp.isEmpty {
            return delayStamp
        }
        
        // Fallback to current timestamp in milliseconds
        return "\(Int(Date().timeIntervalSince1970 * 1000))"
    }
}

// MARK: - XMPPMessage XML parser
func getXMPPMessage(fromXML xml: String) -> XMPPMessage? {
    
    let trimmedXML = xml.trim()
    guard !trimmedXML.isEmpty else {
        printLog("\(#function) | XML string is empty")
        return nil
    }
    
    do {
        let parsedMessage = try XMPPMessage(xmlString: trimmedXML)
        return parsedMessage
    } catch {
        printLog("\(#function) | Failed to parse XML: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Utility: print log
func printLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

// MARK: - Utility: trim string
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
