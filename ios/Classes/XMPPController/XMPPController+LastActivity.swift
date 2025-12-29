//
//  XMPPController+LastActivity.swift
//  xmpp_plugin
//

import Foundation
import XMPPFramework

extension XMPPController: XMPPLastActivityDelegate {

    // MARK: - Delegate
    func numberOfIdleTimeSeconds(for sender: XMPPLastActivity!, queryIQ iq: XMPPIQ!, currentIdleTimeSeconds idleSeconds: UInt) -> UInt {
        printLog("\(#function) | response: \(String(describing: iq)) | idleSeconds: \(idleSeconds)")
        return 0
    }

    func xmppLastActivity(_ sender: XMPPLastActivity!, didReceiveResponse response: XMPPIQ!) {
        printLog("\(#function) | response: \(String(describing: response))")

        var timeInSec = "-1"

        if response.isErrorIQ {
            printLog("\(#function) | Error in XMPPLastActivity IQ: \(String(describing: response))")
            sendLastActivity(withTime: timeInSec)
            return
        }

        guard let eleQuery = response.children?.first as? DDXMLElement else {
            printLog("\(#function) | Invalid XMPPLastActivity IQ-Query: \(String(describing: response))")
            sendLastActivity(withTime: timeInSec)
            return
        }

        if let value = eleQuery.attribute(forName: "seconds")?.stringValue {
            timeInSec = value.trim()
        }

        sendLastActivity(withTime: timeInSec)
    }

    func xmppLastActivity(_ sender: XMPPLastActivity!, didNotReceiveResponse queryID: String!, dueToTimeout timeout: TimeInterval) {
        printLog("\(#function) | queryID: \(String(describing: queryID)) | timeout: \(timeout)")
        sendLastActivity(withTime: "-1")
    }

    // MARK: - Public
    func getLastActivity(withUserJid jid: String) {
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }

        let trimmedJid = jid.trim()
        guard !trimmedJid.isEmpty,
              let vJid = XMPPJID(string: getJIDNameForUser(trimmedJid, withStrem: stream)) else {
            printLog("\(#function) | Invalid UserJid: \(jid)")
            return
        }

        xmppLastActivity.sendQuery(to: vJid)
        printLog("\(#function) | Sent XMPPLastActivity query to: \(vJid)")
    }
}
