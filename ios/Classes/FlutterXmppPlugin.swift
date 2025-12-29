import Flutter
import UIKit
import XMPPFramework

public class FlutterXmppPlugin: NSObject, FlutterPlugin {
    
    static var objEventChannel: FlutterEventChannel = FlutterEventChannel.init()
    static var objConnectionEventChannel: FlutterEventChannel = FlutterEventChannel.init()
    static var objSuccessEventChannel: FlutterEventChannel = FlutterEventChannel.init()
    static var objErrorEventChannel: FlutterEventChannel = FlutterEventChannel.init()
   
    var objEventData: FlutterEventSink?
    var objConnectionEventData: FlutterEventSink?
    var objSuccessEventData: FlutterEventSink?
    var objErrorEventData: FlutterEventSink?

    var objXMPP: XMPPController = XMPPController.sharedInstance
    var objXMPPConnStatus: xmppConnectionStatus = .None {
        didSet {
            postNotification(Name: .xmpp_ConnectionStatus)
        }
    }
    var singalCallBack: FlutterResult?
    var objXMPPLogger: xmppLoggerInfo?

    override init() { super.init() }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_xmpp/method", binaryMessenger: registrar.messenger())
        let instance = FlutterXmppPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        objEventChannel = FlutterEventChannel(name: "flutter_xmpp/stream", binaryMessenger: registrar.messenger())
        objEventChannel.setStreamHandler(SwiftStreamHandler())
        
        objConnectionEventChannel = FlutterEventChannel(name: "flutter_xmpp/connection_event_stream", binaryMessenger: registrar.messenger())
        objConnectionEventChannel.setStreamHandler(ConnectionStreamHandler())
                
        objSuccessEventChannel = FlutterEventChannel(name: "flutter_xmpp/success_event_stream", binaryMessenger: registrar.messenger())
        objSuccessEventChannel.setStreamHandler(SuccessStreamHandler())
        
        objErrorEventChannel = FlutterEventChannel(name: "flutter_xmpp/error_event_stream", binaryMessenger: registrar.messenger())
        objErrorEventChannel.setStreamHandler(ErrorStreamHandler())
        
        APP_DELEGATE.manange_NotifcationObservers()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        addLogger(.receiveFromFlutter, call)
        
        let vMethod: String = call.method.trim()
        printLog(" \(#function) | vMethod \(vMethod)")
        
        switch vMethod {
        case pluginMethod.login: self.performLoginActivity(call, result)
        case pluginMethod.logout: self.performLogoutActivity(call, result)
        case pluginMethod.sendMessage,
             pluginMethod.sendMessageInGroup,
             pluginMethod.sendCustomMessage,
             pluginMethod.sendCustomMessageInGroup:
            self.performSendMessageActivity(call, result)
        case pluginMethod.createMUC: self.performCreateMUCActivity(call, result)
        case pluginMethod.joinMUCGroups: self.performJoinMUCGroupsActivity(call, result)
        case pluginMethod.joinMUCGroup: self.performJoinMUCGroupActivity(call, result)
        case pluginMethod.sendReceiptDelivery: self.performReceiptDeliveryActivity(call, result)
        case pluginMethod.addMembersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Member, actionType: .Add, call, result)
        case pluginMethod.addAdminsInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Admin, actionType: .Add, call, result)
        case pluginMethod.addOwnersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Owner, actionType: .Add, call, result)
        case pluginMethod.getMembers:
            self.performGetMembersInGroupActivity(withMemeberType: .Member, call, result)
        case pluginMethod.getAdmins:
            self.performGetMembersInGroupActivity(withMemeberType: .Admin, call, result)
        case pluginMethod.getOwners:
            self.performGetMembersInGroupActivity(withMemeberType: .Owner, call, result)
        case pluginMethod.removeMembersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Member, actionType: .Remove, call, result)
        case pluginMethod.removeAdminsInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Admin, actionType: .Remove, call, result)
        case pluginMethod.removeOwnersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Owner, actionType: .Remove, call, result)
        case pluginMethod.getLastSeen: self.performLastActivity(call, result)
        case pluginMethod.createRosters: self.createRostersActivity(call, result)
        case pluginMethod.getMyRosters: self.getMyRostersActivity(call, result)
        case pluginMethod.reqMAM: self.manageMAMActivity(call, result)
        case pluginMethod.getPresence: self.getPresenceActivity(call, result)
        case pluginMethod.changeTypingStatus: self.changeTypingStatus(call, result)
        case pluginMethod.changePresenceType: self.changePresence(call, result)
        case pluginMethod.getConnectionStatus: self.getConnectionStatus(call, result)
            
        // NEW: Enable Message Carbons
        case pluginMethod.enableMessageCarbons:
            self.enableMessageCarbonsActivity(call, result)
            
        default:
            guard let vData = call.arguments as? [String: Any] else {
                print("Invalid arguments for \(vMethod): \(String(describing: call.arguments))")
                result(xmppConstants.ERROR)
                return
            }
            print("\(#function) | Unhandled method \(vMethod) | arguments: \(vData)")
            break
        }
    }

    // MARK: - Enable Message Carbons
    func enableMessageCarbonsActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let xmppStream = objXMPP.xmppStream else {
            result(FlutterError(code: "CARBONS_ERROR", message: "XMPP stream not initialized", details: nil))
            return
        }
        let carbons = XMPPCarbons(xmppStream: xmppStream)
        carbons.enableCarbons()
        print("Message Carbons enabled")
        result(xmppConstants.SUCCESS)
    }
}
