//
//  XMPPController+Room.swift
//  flutter_xmpp
//
//  Modern Swift 5+ implementation, fully safe and Flutter-ready
//

import Foundation
import XMPPFramework

extension XMPPController: XMPPRoomDelegate {

    // MARK: - Create or Join a MUC Room
    func createOrJoinMUC(roomJIDString: String, nickname: String, password: String? = nil) {

        // 1️⃣ Validate JID
        guard let roomJID = XMPPJID(string: roomJIDString) else {
            printLog("\(#function) | Invalid room JID: \(roomJIDString)")
            return
        }

        // 2️⃣ Initialize room storage
        let roomStorage = XMPPRoomMemoryStorage()
        
        // 3️⃣ Create XMPPRoom instance
        let room = XMPPRoom(roomStorage: roomStorage, jid: roomJID, dispatchQueue: DispatchQueue.main)
        
        // 4️⃣ Add delegate
        room.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        // 5️⃣ Activate room on the XMPP stream safely
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }
        do {
            try room.activate(stream)
        } catch {
            printLog("\(#function) | Failed to activate room: \(error.localizedDescription)")
            return
        }
        
        // 6️⃣ Join the room with nickname & optional password
        room.join(usingNickname: nickname, history: nil, password: password)
        
        printLog("\(#function) | Room join requested: \(roomJIDString)")
    }

    // MARK: - Handle Room Messages
    func xmppRoom(_ sender: XMPPRoom, didReceive message: XMPPMessage, fromOccupant occupantJID: XMPPJID) {
        printLog("\(#function) | Received MUC message from \(occupantJID.bare): \(message)")
        handleChatMessage(message, withType: xmppChatType.GROUPCHAT, withStream: xmppStream)
    }

    // MARK: - Room Presence
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        let roomJID = sender.roomJID.bare
        printLog("\(#function) | Successfully joined room: \(roomJID)")
        
        // Broadcast join success to Flutter
        broadCastMessageToFlutter(dicData: [
            "type": "muc_join",
            "room": roomJID,
            "status": "joined"
        ])
    }

    func xmppRoom(_ sender: XMPPRoom, occupantDidLeave occupantJID: XMPPJID, withPresence presence: XMPPPresence) {
        printLog("\(#function) | Occupant left: \(occupantJID.bare) in room: \(sender.roomJID.bare)")
    }

    func xmppRoom(_ sender: XMPPRoom, occupantDidJoin occupantJID: XMPPJID, withPresence presence: XMPPPresence) {
        printLog("\(#function) | Occupant joined: \(occupantJID.bare) in room: \(sender.roomJID.bare)")
    }

    func xmppRoomDidLeave(_ sender: XMPPRoom) {
        printLog("\(#function) | Left room: \(sender.roomJID.bare)")
    }

    func xmppRoom(_ sender: XMPPRoom, didFailToJoin error: Error) {
        printLog("\(#function) | Failed to join room: \(sender.roomJID.bare) | Error: \(error.localizedDescription)")
        
        // Optional: notify Flutter about failure
        broadCastMessageToFlutter(dicData: [
            "type": "muc_join",
            "room": sender.roomJID.bare,
            "status": "failed",
            "error": error.localizedDescription
        ])
    }

    // MARK: - Broadcast Room Messages to Flutter
    func broadcastMUCMessageToFlutter(message: XMPPMessage, roomJID: String) {
        let data: [String: Any] = [
            "type": "muc_message",
            "room": roomJID,
            "from": message.from?.bare ?? "",
            "body": message.body() ?? "",
            "msgtype": xmppChatType.GROUPCHAT
        ]
        broadCastMessageToFlutter(dicData: data)
    }

    // MARK: - Helper to send data to Flutter via event channel
    private func broadCastMessageToFlutter(dicData: [String: Any]) {
        if let eventSink = FlutterXmppPlugin.objEventChannel?.setStreamHandler(nil) {
            eventSink(dicData)
        } else {
            printLog("\(#function) | Event sink not available")
        }
    }
}
