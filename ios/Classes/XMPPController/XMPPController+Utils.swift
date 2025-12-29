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
        // Not a mucsub event
        return nil
    }

    printLog("\(#function) | MUCSub event detected")

    // Extract the <message/> child from the pubsub event
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

    // Parse that XML into an XMPPMessage
    guard let xmppMsg = getXMPPMesage(usingXMPPMessageString: itemMessageXML) else {
        printLog("\(#function) | Failed to parse inner message")
        return nil
    }

    // 🛠 Normalize 'from' to bare JID (no resource)
    if let fromJIDObj = xmppMsg.from {
        // XMPPFramework uses 'bareJID' property for resource-less JID
        let bare: String = fromJIDObj.bare
        xmppMsg.from = XMPPJID(string: bare)
    }

    // 🛠 Ensure timestamp exists — Dart expects a non-empty time
    let existingTime = xmppMsg.getTimeElementInfo().trim()
    if existingTime.isEmpty {
        let ts = "\(getTimeStamp())"
        let delay = DDXMLElement(name: "delay", stringValue: ts)
        xmppMsg.addChild(delay)
    }

    return xmppMsg
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
