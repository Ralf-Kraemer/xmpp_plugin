//
//  XMPPController+MAM.swift
//  xmpp_plugin
//
//  Modern Swift 5+ implementation, Flutter-ready
//

import Foundation
import XMPPFramework

// MARK: - MAM
extension XMPPController: XMPPMessageArchiveManagementDelegate {

    /// Request MAM messages for a specific chat JID
    func getMAMMessage(withDMChatJid jid: String,
                       tsBefore: Int64,
                       tsSince: Int64,
                       limit: Int) {

        var fields: [XMLElement] = []
        let defaultLimit = limit > 0 ? limit : 50

        // Timestamp 'before'
        if tsBefore > 0 {
            let date = Date(timeIntervalSince1970: Double(tsBefore) / 1000.0)
            let dateBefore = XMPPMessageArchiveManagement.field(
                withVar: "end", type: nil, andValue: date.xmppDateTimeString
            )
            fields.append(dateBefore)
        }

        // Timestamp 'since'
        if tsSince > 0 {
            let date = Date(timeIntervalSince1970: Double(tsSince) / 1000.0)
            let dateSince = XMPPMessageArchiveManagement.field(
                withVar: "start", type: nil, andValue: date.xmppDateTimeString
            )
            fields.append(dateSince)
        }

        // Normalize JID
        var jidString = jid.trim()
        if !jidString.isEmpty {
            let isFullJid = jidString.contains("@")
            if !isFullJid, let stream = xmppStream {
                jidString = getJIDNameForUser(jidString, withStream: stream)
            }
            let jidField = XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: jidString)
            fields.append(jidField)
        }

        printLog("\(#function) | Requesting MAM: since \(tsSince) | jid: \(jidString) | limit: \(defaultLimit)")

        let resultSet = XMPPResultSet(max: defaultLimit)
        xmppMAM?.retrieveMessageArchive(at: nil, withFields: fields, with: resultSet)
    }

    /// Handle MAM messages safely
    func manageMAMMessage(message: XMPPMessage) {
        let messageType = (message.type ?? xmppChatType.NORMAL).trim()
        guard messageType == xmppChatType.CHAT || messageType == xmppChatType.GROUPCHAT else { return }

        if let stream = xmppStream {
            handle_ChatMessage(message, withType: messageType, withStream: stream)
        } else {
            printLog("\(#function) | xmppStream not initialized, cannot handle message")
        }
    }

    // MARK: - XMPPMessageArchiveManagementDelegate

    func xmppMessageArchiveManagement(_ xmppMAM: XMPPMessageArchiveManagement, didReceiveMAMMessage message: XMPPMessage) {
        guard let forwarded = message.mamResult?.forwardedMessage else {
            printLog("\(#function) | No forwarded message in MAM: \(message)")
            return
        }
        manageMAMMessage(message: forwarded)
    }

    func xmppMessageArchiveManagement(_ xmppMAM: XMPPMessageArchiveManagement, didFinishReceivingMessagesWith resultSet: XMPPResultSet) {
        printLog("\(#function) | Finished receiving MAM messages | resultSet: \(String(describing: resultSet))")
    }

    func xmppMessageArchiveManagement(_ xmppMAM: XMPPMessageArchiveManagement, didFailToReceiveMessages error: XMPPIQ?) {
        printLog("\(#function) | Failed to receive MAM messages | error: \(String(describing: error))")
    }

    func xmppMessageArchiveManagement(_ xmppMAM: XMPPMessageArchiveManagement, didReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | Received MAM form fields: \(iq)")
    }

    func xmppMessageArchiveManagement(_ xmppMAM: XMPPMessageArchiveManagement, didFailToReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | Failed to receive MAM form fields: \(iq)")
    }

    // MARK: - IQ delegate (optional)
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        printLog("\(#function) | Sent IQ: \(iq)")
    }
}

// MARK: - Date extension for XMPP timestamp formatting
extension Date {
    var xmppDateTimeString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Utility: print log
func printLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
