//
//  XMPPSendMessage.swift
//  flutter_xmpp
//
//  Modernized version for Flutter integration
//

import Foundation
import XMPPFramework

extension XMPPController {
    
    // MARK: - Send one-to-one or group message
    func sendMessage(messageBody: String,
                     time: String,
                     receiverJID: String,
                     messageId: String,
                     isGroup: Bool = false,
                     customElement: String,
                     withStream stream: XMPPStream) {
        
        guard let jid = XMPPJID(string: receiverJID) else {
            print("\(#function) | Invalid receiver JID: \(receiverJID)")
            return
        }
        
        let chatType = isGroup ? xmppChatType.GROUPCHAT : xmppChatType.CHAT
        let xmppMessage = XMPPMessage(type: chatType.lowercased(), to: jid)
        xmppMessage.addAttribute(withName: "xmlns", stringValue: "jabber:client")
        xmppMessage.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addBody(messageBody)
        
        // Add timestamp element
        if let eleTime = getTimeElement(withTime: time) {
            xmppMessage.addChild(eleTime)
        }
        
        // Add custom element
        if let ele = getCustomElement(withElementName: customElement) {
            xmppMessage.addChild(ele)
        }
        
        // Add delivery receipt request if enabled
        if xmpp_AutoDeliveryReceipt {
            xmppMessage.addReceiptRequest()
        }
        
        stream.send(xmppMessage)
        addLogger(.sentMessageToServer, xmppMessage)
    }
    
    // MARK: - Send delivery receipt
    func sendMessageDeliveryReceipt(receiptId: String, jid: String, messageId: String, withStream stream: XMPPStream) {
        guard !receiptId.trim().isEmpty,
              !jid.trim().isEmpty,
              !messageId.trim().isEmpty else {
            print("\(#function) | Invalid receiptId, jid, or messageId")
            return
        }
        
        guard let vJid = XMPPJID(string: getJIDNameForUser(jid, withStream: stream)) else { return }
        let xmppMessage = XMPPMessage(type: xmppChatType.NORMAL, to: vJid)
        xmppMessage.addAttribute(withName: "id", stringValue: receiptId)
        
        let received = XMLElement(name: "received", xmlns: "urn:xmpp:receipts")
        received.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addChild(received)
        
        xmppMessage.addReceiptRequest()
        stream.send(xmppMessage)
        
        addLogger(.sentDeliveryReceiptToServer, xmppMessage)
    }
    
    // MARK: - Send ACK for message to Flutter
    func sendAck(for messageId: String) {
        let msgId = messageId.trim()
        guard !msgId.isEmpty else {
            print("\(#function) | MessageId is empty/nil")
            return
        }
        
        let data: [String: Any] = [
            "type": pluginMessType.ACK,
            "id": msgId,
            "from": "",
            "body": "",
            "msgtype": "normal"
        ]
        
        printLog("\(#function) | data: \(data)")
        addLogger(.sentMessageToFlutter, data)
        eventSink?(data)
    }
    
    func sendAckDeliveryReceipt(for messageId: String) {
        let msgId = messageId.trim()
        let data: [String: Any] = [
            "type": pluginMessType.ACK_DELIVERY,
            "id": msgId,
            "from": "",
            "body": "",
            "msgtype": "normal"
        ]
        
        printLog("\(#function) | data: \(data)")
        addLogger(.sentMessageToFlutter, data)
        eventSink?(data)
    }
    
    // MARK: - Broadcast data to Flutter
    func broadCastMessageToFlutter(dicData: [String: Any]) {
        printLog("Broadcasting message: \(dicData)")
        eventSink?(dicData)
    }
    
    // MARK: - Send roster/member/lastActivity info
    func sendMemberList(withUsers users: [String]) {
        printLog("\(#function) | Users: \(users)")
        addLogger(.sentMessageToFlutter, users)
        singalCallBack?(users)
    }
    
    func sendRosters(withUsersJid jids: [String]) {
        printLog("\(#function) | JIDs: \(jids)")
        addLogger(.sentMessageToFlutter, jids)
        singalCallBack?(jids)
    }
    
    func sendLastActivity(withTime time: String) {
        printLog("\(#function) | time: \(time)")
        addLogger(.sentMessageToFlutter, time)
        singalCallBack?(time)
    }
    
    // MARK: - MUC Join/Create Status
    func sendMUCJoinStatus(_ success: Bool, roomName: String, error: String) {
        printLog("\(#function) | success: \(success)")
        addLogger(.sentMessageToFlutter, success)
        updateMUCJoinStatus(withRoomname: roomName, status: success, error: error)
        singalCallBack?(success)
    }
    
    func sendMUCCreateStatus(_ success: Bool) {
        printLog("\(#function) | success: \(success)")
        addLogger(.sentMessageToFlutter, success)
        singalCallBack?(success)
    }
    
    // MARK: - Send presence updates
    func sendPresence(withJid jid: String, type: String, mode: String) {
        let dic: [String: Any] = [
            "type": xmppConstants.presence,
            "from": jid,
            "presenceType": type,
            "presenceMode": mode
        ]
        addLogger(.sentMessageToFlutter, dic)
        eventSink?(dic)
    }
    
    // MARK: - Send typing status
    func sendTypingStatus(withJid jid: String, status: String, withStream stream: XMPPStream) {
        guard let vJid = XMPPJID(string: jid) else { return }
        
        let chatType = xmppChatType.CHAT
        let xmppMessage = XMPPMessage(type: chatType.lowercased(), to: vJid)
        
        let chatState: XMPPMessage.ChatState = {
            switch status {
            case xmppTypingStatus.Active: return .active
            case xmppTypingStatus.Composing: return .composing
            case xmppTypingStatus.Paused: return .paused
            case xmppTypingStatus.Inactive: return .inactive
            case xmppTypingStatus.Gone: return .gone
            default: return .gone
            }
        }()
        
        xmppMessage.addChatState(chatState)
        stream.send(xmppMessage)
        addLogger(.sentMessageToServer, xmppMessage)
    }
    
    // MARK: - Private helpers for custom/time elements
    private func getTimeElement(withTime time: String) -> XMLElement? {
        let ele = XMLElement(name: eleTIME.Name, xmlns: eleTIME.Namespace)
        ele.addChild(XMLElement(name: eleTIME.Key, stringValue: time))
        return ele
    }
    
    private func getCustomElement(withElementName name: String) -> XMLElement? {
        let trimmedName = name.trim()
        guard !trimmedName.isEmpty else { return nil }
        
        let ele = XMLElement(name: eleCustom.Name, xmlns: eleCustom.Namespace)
        ele.addChild(XMLElement(name: eleCustom.Key, stringValue: trimmedName))
        return ele
    }
}
