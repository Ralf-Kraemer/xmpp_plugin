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
        default:
            result(FlutterError(code: "UNSUPPORTED_METHOD", message: "Method \(vMethod) not implemented", details: nil))
        }
    }

    // MARK: - Stub Methods
    func performLoginActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("login stub") }
    func performLogoutActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("logout stub") }
    func performSendMessageActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("sendMessage stub") }
    func performCreateMUCActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("createMUC stub") }
    func performJoinMUCGroupsActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("joinMUCGroups stub") }
    func performJoinMUCGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("joinMUCGroup stub") }
    func performReceiptDeliveryActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) { result("sendReceiptDelivery stub") }

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
