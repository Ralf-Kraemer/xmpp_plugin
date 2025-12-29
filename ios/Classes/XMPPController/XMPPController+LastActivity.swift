//
//  XMPPController+LastActivity.swift
//  xmpp_plugin
//
//  Modern Swift 5+ implementation, Flutter-ready
//

import Foundation
import XMPPFramework

extension XMPPController: XMPPLastActivityDelegate {

    // MARK: - XMPPLastActivityDelegate
    
    /// Returns idle time for a queried user
    func numberOfIdleTimeSeconds(
        for sender: XMPPLastActivity!,
        queryIQ iq: XMPPIQ!,
        currentIdleTimeSeconds idleSeconds: UInt
    ) -> UInt {
        printLog("\(#function) | IQ: \(String(describing: iq)) | idleSeconds: \(idleSeconds)")
        return idleSeconds
    }

    /// Called when response is received
    func xmppLastActivity(_ sender: XMPPLastActivity!, didReceiveResponse response: XMPPIQ!) {
        printLog("\(#function) | Response IQ: \(String(describing: response))")
        
        var timeInSec = "-1"
        
        if response.isErrorIQ {
            printLog("\(#function) | Error IQ received: \(String(describing: response))")
            sendLastActivity(withTime: timeInSec)
            return
        }
        
        guard let eleQuery = response.children?.first as? DDXMLElement else {
            printLog("\(#function) | Invalid IQ query element: \(String(describing: response))")
            sendLastActivity(withTime: timeInSec)
            return
        }
        
        if let secondsAttr = eleQuery.attribute(forName: "seconds")?.stringValue?.trim(),
           !secondsAttr.isEmpty {
            timeInSec = secondsAttr
        }
        
        sendLastActivity(withTime: timeInSec)
    }

    /// Called when no response is received
    func xmppLastActivity(_ sender: XMPPLastActivity!, didNotReceiveResponse queryID: String!, dueToTimeout timeout: TimeInterval) {
        printLog("\(#function) | queryID: \(String(describing: queryID)) | timeout: \(timeout)")
        sendLastActivity(withTime: "-1")
    }

    // MARK: - Public
    
    /// Query last activity for a given user
    func getLastActivity(withUserJid jid: String) {
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }

        let trimmedJid = jid.trim()
        guard !trimmedJid.isEmpty,
              let vJid = XMPPJID(string: getJIDNameForUser(trimmedJid, withStream: stream)) else {
            printLog("\(#function) | Invalid JID: \(jid)")
            return
        }

        xmppLastActivity.sendQuery(to: vJid)
        printLog("\(#function) | Sent XMPPLastActivity query to: \(vJid)")
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
