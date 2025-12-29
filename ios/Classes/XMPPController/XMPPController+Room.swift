//
//  XMPPController+Room.swift
//  xmpp_plugin
//

import Foundation
import XMPPFramework

//MARK: - XMPPRoom
extension XMPPController: XMPPRoomDelegate {

    func createRoom(withRooms arrRooms: [groupInfo]) {
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }

        for objRoom in arrRooms {
            let roomName = objRoom.name.trim()
            if roomName.isEmpty {
                printLog("\(#function) | roomName nil/empty")
                sendMUCCreateStatus(false)
                continue
            }

            guard let roomJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: roomName)) else {
                printLog("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
                sendMUCCreateStatus(false)
                continue
            }

            let userId = getUserId(usingXMPPStream: stream)
            if userId.isEmpty {
                printLog("\(#function) | XMPP UserId is nil/empty")
                sendMUCCreateStatus(false)
                continue
            }

            addUpdateGroupInfo(objGroupInfo: objRoom)

            let roomMemory = XMPPRoomMemoryStorage()
            let xmppRoom = XMPPRoom(roomStorage: roomMemory, jid: roomJID)
            xmppRoom.activate(stream)
            xmppRoom.addDelegate(self, delegateQueue: .main)

            let history = getXMPPRoomHistory(withTime: 0)
            xmppRoom.join(usingNickname: userId, history: history)
            xmppRoom.fetchConfigurationForm()

            printLog("\(#function) | Created XMPPRoom: \(roomName)")
        }
    }

    func joinRoom(roomName: String, time: Int64) {
        guard let stream = xmppStream else {
            printLog("\(#function) | xmppStream not initialized")
            return
        }

        let trimmedRoom = roomName.trim()
        if trimmedRoom.isEmpty {
            sendMUCJoinStatus(false, roomName, "Room name can't be empty")
            return
        }

        let userId = getUserId(usingXMPPStream: stream)
        if userId.isEmpty {
            sendMUCJoinStatus(false, roomName, "User ID can't be empty")
            return
        }

        guard let xmppJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: trimmedRoom)) else {
            sendMUCJoinStatus(false, roomName, "Invalid Room Name")
            return
        }

        let objRoom = groupInfo()
        objRoom.name = trimmedRoom
        addUpdateGroupInfo(objGroupInfo: objRoom)

        let xmppRoom = XMPPRoom(roomStorage: XMPPRoomMemoryStorage(), jid: xmppJID)
        xmppRoom.activate(stream)
        xmppRoom.addDelegate(self, delegateQueue: .main)

        let history = getXMPPRoomHistory(withTime: time)
        xmppRoom.join(usingNickname: userId, history: history)

        printLog("\(#function) | Joined XMPPRoom: \(roomName) | userId: \(userId) | history: \(history)")
    }

    func getXMPPRoomJidName(withRoomName roomName: String) -> String {
        guard let host = xmppStream?.hostName?.trim(), !host.isEmpty else {
            return roomName
        }

        if roomName.contains(xmppConstants.Conference) {
            return roomName
        }
        return "\(roomName)@\(xmppConstants.Conference).\(host)"
    }

    func getXMPPRoomHistory(withTime time: Int64) -> XMLElement {
        let history = XMLElement(name: "history")
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let seconds = (currentTime - time) / 1000
        history.addAttribute(withName: "seconds", stringValue: "\(seconds)")
        return history
    }

    func addUpdateGroupInfo(objGroupInfo: groupInfo) {
        let roomName = objGroupInfo.name.trim()
        guard !roomName.isEmpty else { return }

        if let index = arrGroups.firstIndex(where: { $0.name == roomName }) {
            arrGroups[index] = objGroupInfo
            printLog("\(#function) | Updated XMPPRoom: \(roomName)")
        } else {
            arrGroups.append(objGroupInfo)
            printLog("\(#function) | Added new XMPPRoom: \(roomName)")
        }
    }

    func updateGroupInfoIntoXMPPRoomCreatedAndJoined(roomXMPP: XMPPRoom, roomName: String) {
        guard let index = arrGroups.firstIndex(where: { $0.name == roomName }) else {
            printLog("\(#function) | Not found XMPPRoom in GroupInfo list: \(roomName)")
            return
        }
        arrGroups[index].objRoomXMPP = roomXMPP
        printLog("\(#function) | Updated XMPPRoom object: \(roomName)")
    }

    // MARK: - XMPPRoomDelegate
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        guard let roomName = sender.myRoomJID?.bareJID.user else {
            sendMUCCreateStatus(false)
            return
        }
        sendMUCCreateStatus(true)
        updateGroupInfoIntoXMPPRoomCreatedAndJoined(roomXMPP: sender, roomName: roomName)
        printLog("\(#function) | Room created: \(roomName)")
    }

    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        guard let roomName = sender.myRoomJID?.bareJID.user else {
            sendMUCJoinStatus(false, "", "Join Error")
            return
        }
        sendMUCJoinStatus(true, roomName, "")
        updateGroupInfoIntoXMPPRoomCreatedAndJoined(roomXMPP: sender, roomName: roomName)
        printLog("\(#function) | Room joined: \(roomName)")
    }
}
