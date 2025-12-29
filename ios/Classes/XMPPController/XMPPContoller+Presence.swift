//
//  XMPPController+Presence.swift
//  xmpp_plugin
//

import Foundation
import XMPPFramework

// MARK: - XMPPPresence
extension XMPPController {

    /// Query the presence of a user
    func getPresenceOfUser(withJid jid: String) {
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }

        let trimmedJid = jid.trim()
        guard !trimmedJid.isEmpty,
              let vJid = XMPPJID(string: getJIDNameForUser(trimmedJid, withStrem: stream)) else {
            if let callback = APP_DELEGATE.singalCallBack {
                callback(xmppConstants.DataNil)
            }
            return
        }

        let obj = xmppRosterStorage?.user(for: vJid, xmppStream: stream, managedObjectContext: nil)
        printLog("\(#function) | User presence object: \(String(describing: obj))")
    }

    // MARK: - Stream Delegate
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        printLog("\(#function) | Sent presence: \(presence)")
    }

    func xmppStream(_ sender: XMPPStream, didFailToSend presence: XMPPPresence, error: Error) {
        printLog("\(#function) | Failed to send presence: \(presence) | error: \(error)")
    }

    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        printLog("\(#function) | Received presence: \(presence)")

        if presence.isErrorPresence {
            let errorMessage = presence.getElements(withKey: "error").first?.getValue(withKey: "text") ?? ""
            printLog("\(#function) | Error presence: \(errorMessage)")
            APP_DELEGATE.updateMUCJoinStatus(withRoomname: presence.fromStr ?? "", status: false, error: errorMessage)
            return
        }

        let vFrom = presence.fromStr ?? ""
        let vType = presence.type ?? ""
        var vMode = presence.show ?? ""
        if vMode.trim().isEmpty { vMode = vType }

        sendPresence(withJid: vFrom, type: vType, move: vMode)
    }
}
