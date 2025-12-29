import Flutter
import UIKit
import XMPPFramework

// MARK: - FlutterXmppPlugin
public class FlutterXmppPlugin: NSObject, FlutterPlugin {

    // MARK: - Event Channels
    static var objEventChannel: FlutterEventChannel?
    static var objConnectionEventChannel: FlutterEventChannel?
    static var objSuccessEventChannel: FlutterEventChannel?
    static var objErrorEventChannel: FlutterEventChannel?

    var objEventData: FlutterEventSink?
    var objConnectionEventData: FlutterEventSink?
    var objSuccessEventData: FlutterEventSink?
    var objErrorEventData: FlutterEventSink?

    var objXMPP: XMPPController = XMPPController.sharedInstance
    var objXMPPConnStatus: xmppConnectionStatus = .None {
        didSet { postNotification(Name: .xmpp_ConnectionStatus) }
    }
    var singalCallBack: FlutterResult?

    override init() { super.init() }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_xmpp/method", binaryMessenger: registrar.messenger())
        let instance = FlutterXmppPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        objEventChannel = FlutterEventChannel(name: "flutter_xmpp/stream", binaryMessenger: registrar.messenger())
        objEventChannel?.setStreamHandler(GenericStreamHandler())

        objConnectionEventChannel = FlutterEventChannel(name: "flutter_xmpp/connection_event_stream", binaryMessenger: registrar.messenger())
        objConnectionEventChannel?.setStreamHandler(GenericStreamHandler())

        objSuccessEventChannel = FlutterEventChannel(name: "flutter_xmpp/success_event_stream", binaryMessenger: registrar.messenger())
        objSuccessEventChannel?.setStreamHandler(GenericStreamHandler())

        objErrorEventChannel = FlutterEventChannel(name: "flutter_xmpp/error_event_stream", binaryMessenger: registrar.messenger())
        objErrorEventChannel?.setStreamHandler(GenericStreamHandler())
    }

    // MARK: - Method Call Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let vMethod = call.method

        switch vMethod {
        case "login": performLoginActivity(call, result)
        case "logout": performLogoutActivity(call, result)
        case "sendMessage": performSendMessageActivity(call, result)
        case "createMUC": performCreateMUCActivity(call, result)
        case "joinMUCGroups": performJoinMUCGroupsActivity(call, result)
        case "joinMUCGroup": performJoinMUCGroupActivity(call, result)
        case "sendReceiptDelivery": performReceiptDeliveryActivity(call, result)
        case "enableMessageCarbons": enableMessageCarbonsActivity(call, result)
        case "requestArchivedMessages": performRequestArchivedMessages(call, result) // <-- NEW
        default:
            result(FlutterError(code: "UNSUPPORTED_METHOD", message: "Method \(vMethod) not implemented", details: nil))
        }
    }

    // MARK: - Full Implementations
    func performLoginActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        objXMPP.connect { success, error in
            if success { result("LOGIN_SUCCESS") }
            else { result(FlutterError(code: "LOGIN_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    func performLogoutActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        do {
            try objXMPP.disconnect()
            result("LOGOUT_SUCCESS")
        } catch {
            result(FlutterError(code: "LOGOUT_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    func performSendMessageActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let to = args["to_jid"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing to_jid or body", details: nil))
            return
        }
        objXMPP.sendMessage(to: to, body: body) { success, error in
            if success { result("MESSAGE_SENT") }
            else { result(FlutterError(code: "SEND_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    func performCreateMUCActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let roomName = args["room_name"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing room_name", details: nil))
            return
        }
        objXMPP.createMUC(roomName: roomName) { success, error in
            if success { result("MUC_CREATED") }
            else { result(FlutterError(code: "CREATE_MUC_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    func performJoinMUCGroupsActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        objXMPP.joinAllMUCGroups { success, error in
            if success { result("JOINED_ALL_MUCS") }
            else { result(FlutterError(code: "JOIN_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    func performJoinMUCGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let roomJid = args["room_jid"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing room_jid", details: nil))
            return
        }
        objXMPP.joinMUC(roomJid: roomJid) { success, error in
            if success { result("JOINED_MUC") }
            else { result(FlutterError(code: "JOIN_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    func performReceiptDeliveryActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let toJid = args["to_jid"] as? String,
              let msgId = args["id"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing to_jid or id", details: nil))
            return
        }
        objXMPP.sendReceipt(to: toJid, id: msgId) { success, error in
            if success { result("RECEIPT_SENT") }
            else { result(FlutterError(code: "RECEIPT_FAILED", message: error?.localizedDescription ?? "Unknown", details: nil)) }
        }
    }

    // MARK: - Enable Message Carbons
    func enableMessageCarbonsActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard objXMPP.isConnected() else {
            result(FlutterError(code: "CARBONS_ERROR", message: "XMPP stream is not connected", details: nil))
            return
        }
        let carbons = XMPPCarbons(xmppStream: objXMPP.xmppStream)
        carbons.enableCarbons()
        result("CARBONS_ENABLED")
    }

    // MARK: - Request Archived Messages (MAM)
    func performRequestArchivedMessages(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
            return
        }

        let jid = args["jid"] as? String ?? ""             // JID of user or room
        let tsBefore = args["ts_before"] as? Int64 ?? 0    // before timestamp in ms
        let tsSince = args["ts_since"] as? Int64 ?? 0      // since timestamp in ms
        let limit = args["limit"] as? Int ?? 50            // max messages

        objXMPP.requestArchivedMessages(jid: jid, tsBefore: tsBefore, tsSince: tsSince, limit: limit) { messages in
            // Convert messages to Flutter-friendly array of dictionaries
            result(messages)
        }
    }

}

// MARK: - Generic Stream Handler
class GenericStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - Utility Notification
public func postNotification(Name: Notification.Name) {
    NotificationCenter.default.post(name: Name, object: nil)
}
