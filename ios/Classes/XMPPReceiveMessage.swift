//
//  XMPPReceiveMessage.swift
//  flutter_xmpp
//
//  Modernized for Flutter EventChannel with enforced safety
//

import Foundation
import XMPPFramework

extension XMPPController {

    // MARK: - Handle incoming chat messages
    func handleChatMessage(_ message: XMPPMessage, withType type: String, withStream stream: XMPPStream) {
        
        // Log raw message for debugging
        printLog("Handling message: \(message)")

        guard let sendData = eventSink else {
            print("\(#function) | eventSink is nil")
            return
        }

        // Initialize custom Message object
        var objMessage = Message()
        objMessage.initWithMessage(message)

        // Validate message ID
        let messageId = objMessage.id.trim()
        guard !messageId.isEmpty else {
            print("\(#function) | Message ID is nil or empty")
            return
        }

        // Extract custom text if any
        let customText = message.getCustomElementInfo(withKey: eleCustom.Key)

        let data: [String: Any] = [
            "type": pluginMessType.Message,
            "id": messageId,
            "from": objMessage.senderJid,
            "body": objMessage.message,
            "customText": customText,
            "msgtype": type,
            "senderJid": objMessage.senderJid,
            "time": objMessage.time
        ]

        // Ensure EventChannel call is on main thread
        DispatchQueue.main.async {
            sendData(data)
        }
    }

    // MARK: - Handle normal chat messages and chat state updates
    func handleNormalChatMessage(_ message: XMPPMessage, withStream stream: XMPPStream) {

        // 1️⃣ Handle XMPP delivery receipts
        if message.hasReceiptResponse {
            guard let receiptId = message.receiptResponseID else {
                print("\(#function) | ReceiptResponseID is empty or nil")
                return
            }
            self.sendAckDeliveryReceipt(for: receiptId)
            return
        }

        // 2️⃣ Handle chat states
        var chatState: String = ""
        if message.hasChatState {
            if message.hasComposingChatState { chatState = "composing" }
            else if message.hasGoneChatState { chatState = "gone" }
            else if message.hasPausedChatState { chatState = "paused" }
            else if message.hasActiveChatState { chatState = "active" }
            else if message.hasInactiveChatState { chatState = "inactive" }
        }

        // 3️⃣ Initialize message object
        var objMessage = Message()
        objMessage.initWithMessage(message)

        let fromJid = message.fromStr ?? ""

        let data: [String: Any] = [
            "type": "chatstate",
            "id": objMessage.id,
            "from": fromJid,
            "body": objMessage.message,
            "customText": "",
            "msgtype": "normal",
            "senderJid": fromJid,
            "time": objMessage.time,
            "chatStateType": chatState
        ]

        // 4️⃣ Broadcast to Flutter EventChannel on main thread
        DispatchQueue.main.async {
            self.eventSink?(data)
        }

        // Also send via your custom broadcast method
        self.broadCastMessageToFlutter(dicData: data)
    }
}
