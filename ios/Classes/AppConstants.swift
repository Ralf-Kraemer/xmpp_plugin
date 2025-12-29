//
//  AppConstants.swift
//  Runner
//
//  Updated for FlutterXmppPlugin singleton
//

import Foundation
import XMPPFramework

// MARK: - XMPP Config
public var xmpp_HostName: String = ""
public var xmpp_HostPort: Int16 = 0
public var xmpp_UserId: String = ""
public var xmpp_UserPass: String = ""
public var xmpp_Resource: String = ""
public var xmpp_RequireSSLConnection: Bool = false
public var xmpp_AutoDeliveryReceipt: Bool = false
public var xmpp_AutoReConnection: Bool = true
public var xmpp_UseStream: Bool = true

let default_isPersistent: Bool = false

// MARK: - Plugin Methods
struct pluginMethod {
    static let login = "login"
    static let logout = "logout"
    static let sendMessage = "send_message"
    static let sendMessageInGroup = "send_group_message"
    static let sendCustomMessage = "send_custom_message"
    static let sendCustomMessageInGroup = "send_customgroup_message"
    static let createMUC = "create_muc"
    static let joinMUCGroups = "join_muc_groups"
    static let joinMUCGroup = "join_muc_group"
    static let sendReceiptDelivery = "send_delivery_receipt"
    static let addMembersInGroup = "add_members_in_group"
    static let addAdminsInGroup = "add_admins_in_group"
    static let addOwnersInGroup = "add_owners_in_group"
    static let removeMembersInGroup = "remove_members_from_group"
    static let removeAdminsInGroup = "remove_admins_from_group"
    static let removeOwnersInGroup = "remove_owners_from_group"
    static let getMembers = "get_members"
    static let getAdmins = "get_admins"
    static let getOwners = "get_owners"
    static let getLastSeen = "get_last_seen"
    static let createRosters = "create_roster"
    static let getMyRosters = "get_my_rosters"
    static let reqMAM = "request_mam"
    static let getPresence = "get_presence"
    static let changeTypingStatus = "change_typing_status"
    static let changePresenceType = "change_presence_type"
    static let getConnectionStatus = "get_connection_status"
    static let enableMessageCarbons = "enable_message_carbons"
}

// MARK: - Message Types
struct pluginMessType {
    static let Incoming = "incoming"
    static let Message = "Message"
    static let ACK = "Ack"
    static let ACK_DELIVERY = "Delivery-Ack"
    static let ACK_READ = "Read-Ack"
}

// MARK: - Chat Types
struct xmppChatType {
    static let GROUPCHAT = "groupchat"
    static let CHAT = "chat"
    static let NORMAL = "normal"
}

// MARK: - Constants
struct xmppConstants {
    static let Conference = "conference"
    static let ERROR = "ERROR"
    static let SUCCESS = "SUCCESS"
    static let Resource = "iOS"
    static let BODY = "body"
    static let ID = "id"
    static let TO = "to"
    static let FROM = "from"
    static let DataNil = "Data nil"
    static let errorMessOfMUC = "Owner privileges required"
    static let presence = "presence"
}

// MARK: - Connection Status
struct xmppConnStatus {
    static let Processing = "connecting"
    static let Authenticated = "authenticated"
    static let Failed = "failed"
    static let Disconnect = "disconnected"
    static let Connected = "connected"
}

// MARK: - MUC Roles
struct xmppMUCRole {
    static let Owner = "owner"
    static let Admin = "admin"
    static let Member = "member"
    static let None = "none"
}

// MARK: - Typing Status
struct xmppTypingStatus {
    static let Active = "active"
    static let Composing = "composing"
    static let Paused = "paused"
    static let Inactive = "inactive"
    static let Gone = "gone"
}

// MARK: - Group Info
class groupInfo {
    var name: String = ""
    var isPersistent: Bool = default_isPersistent
    var objRoomXMPP: XMPPRoom?

    init() {}
    init(name: String, isPersistent: Bool) {
        self.name = name
        self.isPersistent = isPersistent
    }
    init(name: String, isPersistent: Bool, objRoomXMPP: XMPPRoom?) {
        self.init(name: name, isPersistent: isPersistent)
        self.objRoomXMPP = objRoomXMPP
    }
}

// MARK: - Logger Info
class xmppLoggerInfo {
    var isLogEnable: Bool = false
    var logPath: String = ""
    init() {}
}

// MARK: - XML Elements
struct eleTIME {
    static let Name = "TIME"
    static let Namespace = "urn:xmpp:time"
    static let Key = "ts"
}

struct eleCustom {
    static let Name = "CUSTOM"
    static let Namespace = "urn:xmpp:custom"
    static let Key = "custom"
}

struct errorCustom {
    static let Name = "error"
    static let Key = "text"
}

// MARK: - Enums
enum XMPPControllerError: Error {
    case wrongUserJID
}

enum xmppConnectionStatus: Int {
    case None, Processing, Sucess, Disconnect, Failed, Connected
    var value: Int { rawValue }
}

enum xmppMUCUserType { case Owner, Admin, Member }
enum xmppMUCUserActionType { case Add, Remove }
enum Status { case Online, Offline }

enum LogType: String {
    case none = "default"
    case receiveFromFlutter = "methodReceiveFromFlutter"
    case receiveStanzaAckFromServer = "receiveStanzaAckFromServer"
    case receiveMessageFromServer = "receiveMessageFromServer"
    case sentMessageToFlutter = "sentMessageToFlutter"
    case sentMessageToServer = "sentMessageToServer"
    case sentCustomMessageToServer = "sentCustomMessageToServer"
    case sentDeliveryReceiptToServer = "sentDeliveryReceiptToServer"
}

// MARK: - Notification Names
extension Notification.Name {
    static let xmpp_ConnectionReq = Notification.Name("xmpp_ConnectionReq")
    static let xmpp_ConnectionStatus = Notification.Name("xmpp_ConnectionStatus")
}

// MARK: - String Extension
extension String {
    var boolValue: Bool { (self as NSString).boolValue }
    func trim() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var containsWhitespace: Bool { rangeOfCharacter(from: .whitespacesAndNewlines) != nil }
}
