//
//  XMPPController+Utils.swift
//  xmpp_plugin
//
//  Updated to correctly handle MUCSUB messages for iOS,
//  aligned with Dart expectations.
//

import Foundation
import XMPPFramework

/// Manage MUCSUB messages — returns an XMPPMessage if found
func manage_MucSubMesage(_ message: XMPPMessage) -> XMPPMessage? {

    // Only match if the "event" element URI is MUCSUB
    let events = message.elements(
        forName: "event",
        xmlns: "http://jabber.org/protocol/pubsub#event"
    )

    guard events.first != nil else {
        return nil
    }

    printLog("\(#function) | MUCSub event detected")

    // Extract <message> from the nested structure
    guard
        let itemMessageXML = message
            .element(forName: "event", xmlns: "http://jabber.org/protocol/pubsub#event")?
            .element(forName: "items")?
            .element(forName: "item")?
            .element(forName: "message")?
            .xmlString
    else {
        printLog("\(#function) | No nested message found")
        return nil
    }

    guard let xmppMsg = getXMPPMesage(usingXMPPMessageString: itemMessageXML) else {
        printLog("\(#function) | Failed to parse inner message")
        return nil
    }

    // 🛠 Extract bare JID safely
    let bareJID: String = xmppMsg.from?.bare ?? ""

    // 🛠 Ensure timestamp exists — Dart expects a non-empty time
    let time: String = xmppMsg.getTimestamp() // uses the extension I suggested
    if xmppMsg.element(forName: "delay") == nil {
        let delay = DDXMLElement(name: "delay", stringValue: time)
        xmppMsg.addChild(delay)
    }

    // Return the normalized message
    return xmppMsg
}

// MARK: - XMPPMessage timestamp helper
extension XMPPMessage {
    func getTimestamp() -> String {
        // <time> custom element
        if let timeElement = self.element(forName: "time", xmlns: "urn:xmpp:time"),
           let timeValue = timeElement.stringValue?.trim(), !timeValue.isEmpty {
            return timeValue
        }

        // XEP-0203 <delay> element
        if let delayElement = self.element(forName: "delay", xmlns: "urn:xmpp:delay"),
           let delayValue = delayElement.attributeStringValue(forName: "stamp")?.trim(),
           !delayValue.isEmpty {
            return delayValue
        }

        // fallback
        return "\(Int(Date().timeIntervalSince1970 * 1000))"
    }
}

/// Parse an XMPP message from raw XML safely
func getXMPPMesage(usingXMPPMessageString xml: String) -> XMPPMessage? {

    let trimmed = xml.trim()
    guard !trimmed.isEmpty else {
        printLog("\(#function) | Empty XML message string")
        return nil
    }

    do {
        let parsedMessage = try XMPPMessage(xmlString: trimmed)
        return parsedMessage
    } catch let error {
        printLog("\(#function) | XML parse failed: \(error.localizedDescription)")
        return nil
    }
}
