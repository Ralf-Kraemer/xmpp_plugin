//
//  XMPPController+Roster.swift
//  xmpp_plugin
//
//  Updated for lib/ alignment
//

import Foundation
import XMPPFramework

//MARK: - XMPPRoster
extension XMPPController: XMPPRosterDelegate {

    // Create roster / subscribe to a user
    func createRosters(withUserJid jid: String) {
        let trimmedJid = jid.trim()
        printLog("\(#function) | withUserJid: \(trimmedJid)")
        
        guard !trimmedJid.isEmpty else {
            print("\(#function) | userJid is empty.")
            return
        }
        
        guard let vJid = XMPPJID(string: getJIDNameForUser(trimmedJid, withStrem: xmppStream!)) else {
            print("\(#function) | Invalid JID: \(jid)")
            return
        }
        
        xmppRoster?.subscribePresence(toUser: vJid)
        printLog("\(#function) | Sent presence subscription to \(vJid)")
    }

    // Get current roster and send to Flutter
    func getMyRosters() {
        var arrJidString: [String] = []
        guard let jids = xmppRosterStorage?.jids(for: xmppStream!) else {
            printLog("\(#function) | No roster found.")
            sendRosters(withUsersJid: arrJidString)
            return
        }
        
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
        printLog("\(#function) | Received subscription request: \(presence.fromStr ?? "--")")
        // Optional: automatically accept?
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
