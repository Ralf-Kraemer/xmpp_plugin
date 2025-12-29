//
//  XMPPController+Roster.swift
//  xmpp_plugin
//
//  Updated for Swift 5 / Xcode 15, Flutter-ready
//

import Foundation
import XMPPFramework

// MARK: - XMPPRoster
extension XMPPController: XMPPRosterDelegate {

    // MARK: - Create roster / subscribe to a user
    func createRosters(withUserJid jid: String) {
        let trimmedJid = jid.trim()
        printLog("\(#function) | withUserJid: \(trimmedJid)")
        
        guard !trimmedJid.isEmpty else {
            printLog("\(#function) | userJid is empty.")
            return
        }
        
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }
        
        let fullJid = getJIDNameForUser(trimmedJid)
        guard let vJid = XMPPJID(string: fullJid) else {
            printLog("\(#function) | Invalid JID: \(jid)")
            return
        }
        
        xmppRoster?.subscribePresence(toUser: vJid)
        printLog("\(#function) | Sent presence subscription to \(vJid)")
    }

    // MARK: - Get current roster and send to Flutter
    func getMyRosters() {
        var arrJidString: [String] = []
        
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            sendRosters(withUsersJid: arrJidString)
            return
        }
        
        guard let storage = xmppRosterStorage else {
            printLog("\(#function) | Roster storage not initialized")
            sendRosters(withUsersJid: arrJidString)
            return
        }
        
        let jids = storage.jids(for: stream) ?? []
        for jid in jids {
            let strJid = jid.description.trim()
            if !strJid.isEmpty {
                arrJidString.append(strJid)
            }
        }
        
        sendRosters(withUsersJid: arrJidString)
        printLog("\(#function) | Sent roster to Flutter: \(arrJidString)")
    }

    // MARK: - XMPPRosterDelegate callbacks
    
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        let fromJid = presence.from?.bare ?? "--"
        printLog("\(#function) | Received subscription request from: \(fromJid)")
        // Optional: automatically accept
        // sender.acceptPresenceSubscriptionRequest(from: presence.from, andAddToRoster: true)
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        printLog("\(#function) | Received roster push: \(iq)")
        getMyRosters() // Refresh Flutter roster
    }
    
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster, withVersion version: String) {
        printLog("\(#function) | Begin populating roster, version: \(version)")
    }
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        printLog("\(#function) | Finished populating roster")
        getMyRosters() // Send final roster to Flutter
    }
}

// MARK: - Utility
extension XMPPController {
    /// Forward roster to Flutter via event channel
    func sendRosters(withUsersJid jids: [String]) {
        if let eventSink = FlutterXmppPlugin.objEventChannel?.setStreamHandler(nil) {
            eventSink(["event": "roster_update", "jids": jids])
        } else {
            printLog("\(#function) | Event sink not available")
        }
    }
}

// MARK: - String trimming helper
extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Debug logging
func printLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
