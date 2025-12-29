//
//  XMPPController+MAM.swift
//  xmpp_plugin
//
//  Fixed for lib/ alignment
//

import Foundation
import XMPPFramework

//MARK: - MAM
extension XMPPController {

    func getMAMMessage(withDMChatJid jid: String,
                       tsBefore: Int64,
                       tsSince: Int64,
                       limit: Int) {

        let vType: String? = nil
        var fields: [XMLElement] = []
        var defaultLimit: Int = limit > 0 ? limit : 50

        // Before timestamp
        if tsBefore > 0 {
            let date = Date(timeIntervalSince1970: Double(tsBefore)/1000.0)
            let xmppDateString = date.xmppDateTimeString
            let dateBefore = XMPPMessageArchiveManagement.field(withVar: "end", type: vType, andValue: xmppDateString)
            fields.append(dateBefore)
        }

        // Since timestamp
        if tsSince > 0 {
            let date = Date(timeIntervalSince1970: Double(tsSince)/1000.0)
            let xmppDateString = date.xmppDateTimeString
            let dateSince = XMPPMessageArchiveManagement.field(withVar: "start", type: vType, andValue: xmppDateString)
            fields.append(dateSince)
        }

        // Normalize JID
        var jidString = jid
        if !jid.trim().isEmpty {
            let isFullJid = (jid.components(separatedBy: "@").count == 2)
            if !isFullJid {
                jidString = getJIDNameForUser(jid, withStream: xmppStream!)
            }
            let aJIDField = XMPPMessageArchiveManagement.field(withVar: "with", type: nil, andValue: jidString)
            fields.append(aJIDField)
        }

        printLog("\(#function) | req MAM: since \(tsSince) | jid: \(jidString) | limit: \(defaultLimit)")

        let xmppRS = XMPPResultSet(max: defaultLimit)
        xmppMAM?.retrieveMessageArchive(at: nil, withFields: fields, with: xmppRS)
    }

    func manageMAMMessage(message: XMPPMessage) {
        printLog("\(#function) | Manage MAM message: \(message)")
        let vMessType = (message.type ?? xmppChatType.NORMAL).trim()
        if vMessType == xmppChatType.CHAT || vMessType == xmppChatType.GROUPCHAT {
            handle_ChatMessage(message, withType: vMessType, withStream: xmppStream!)
        }
    }

    // MARK: - XMPPMessageArchiveManagement Delegate

    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveMAMMessage message: XMPPMessage) {
        guard let forwarded = message.mamResult?.forwardedMessage else {
            printLog("\(#function) | No forwarded message in MAM: \(message)")
            return
        }
        manageMAMMessage(message: forwarded)
    }

    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFinishReceivingMessagesWith resultSet: XMPPResultSet) {
        printLog("\(#function) | Finished receiving MAM messages | resultSet: \(String(describing: resultSet))")
    }

    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFailToReceiveMessages error: XMPPIQ?) {
        printLog("\(#function) | Failed to receive MAM messages | error: \(String(describing: error))")
    }

    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | Received MAM form fields: \(iq)")
    }

    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFailToReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | Failed to receive MAM form fields: \(iq)")
    }

    // MARK: - IQ delegate
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        printLog("\(#function) | Sent IQ: \(iq)")
    }
}
