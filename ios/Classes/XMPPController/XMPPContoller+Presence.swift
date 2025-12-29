//
//  XMPPController+Presence.swift
//  xmpp_plugin
//
//  Modern Swift 5+ implementation, Flutter-ready
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
              let vJid = XMPPJID(string: getJIDNameForUser(trimmedJid, withStream: stream)) else {
            APP_DELEGATE.singalCallBack?(xmppConstants.DataNil)
            return
        }

        let userPresence = xmppRosterStorage?.user(for: vJid, xmppStream: stream, managedObjectContext: nil)
        printLog("\(#function) | User presence object: \(String(describing: userPresence))")
    }

    // MARK: - XMPPStream Delegate: Sending Presence
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        printLog("\(#function) | Sent presence: \(presence)")
    }

    func xmppStream(_ sender: XMPPStream, didFailToSend presence: XMPPPresence, error: Error) {
        printLog("\(#function) | Failed to send presence: \(presence) | error: \(error.localizedDescription)")
    }

    // MARK: - XMPPStream Delegate: Receiving Presence
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        printLog("\(#function) | Received presence: \(presence)")

        // Handle error presence
        if presence.isErrorPresence {
            let errorMessage = presence.elements(forName: "error")
                .first?
                .element(forName: "text")?
                .stringValue ?? ""
            printLog("\(#function) | Error presence: \(errorMessage)")
            APP_DELEGATE.updateMUCJoinStatus(
                withRoomname: presence.fromStr ?? "",
                status: false,
                error: errorMessage
            )
            return
        }

        let vFrom = presence.fromStr ?? ""
        let vType = presence.type ?? ""
        var vMode = presence.show ?? ""
        if vMode.trim().isEmpty { vMode = vType }

        sendPresence(withJid: vFrom, type: vType, mode: vMode)
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
