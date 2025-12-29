//
//  XMPPController.swift
//

import UIKit
import XMPPFramework

class XMPPController: NSObject {

    // MARK: - Singleton
    static let sharedInstance = XMPPController()

    // MARK: - XMPP Components
    var xmppStream: XMPPStream!
    var xmppReconnect: XMPPReconnect!
    var xmppRoster: XMPPRoster?
    var xmppRosterStorage: XMPPRosterCoreDataStorage?
    var xmppLastActivity: XMPPLastActivity!
    var xmppMAM: XMPPMessageArchiveManagement?

    var xmppRoom: XMPPRoom?
    var xmppStreamManagement: XMPPStreamManagement!

    // MARK: - User/Connection Info
    internal var hostName: String = ""
    internal var hostPort: Int16 = 0
    internal var userId: String = ""
    internal var userJID: XMPPJID!
    private var password: String = ""
    internal var arrGroups: [groupInfo] = []

    // MARK: - Initializers
    override init() {
        super.init()
    }

    init(hostName: String, hostPort: Int16, userId: String, password: String, resource: String) throws {
        super.init()

        let stUserJid = "\(userId)@\(hostName)"
        guard let userJID = XMPPJID(string: stUserJid, resource: resource) else {
            APP_DELEGATE.objXMPPConnStatus = .Failed
            throw XMPPControllerError.wrongUserJID
        }

        self.hostName = hostName
        self.hostPort = hostPort
        self.userId = userId
        self.password = password
        self.userJID = userJID

        setupStream()
        setupReconnect()
        setupRoster()
        setupLastActivity()
        setupMAM()
    }

    // MARK: - Setup
    private func setupStream() {
        xmppStream = XMPPStream()
        xmppStream.myJID = userJID
        xmppStream.hostName = hostName
        xmppStream.hostPort = UInt16(hostPort)
        if xmpp_RequireSSLConnection { xmppStream.startTLSPolicy = .required }
        xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
    }

    private func setupReconnect() {
        if xmpp_AutoReConnection {
            xmppReconnect = XMPPReconnect()
            xmppReconnect.manualStart()
            xmppReconnect.activate(xmppStream)
            xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
    }

    private func setupRoster() {
        xmppRosterStorage = XMPPRosterCoreDataStorage()
        if let storage = xmppRosterStorage {
            xmppRoster = XMPPRoster(rosterStorage: storage)
            xmppRoster?.autoFetchRoster = true
            xmppRoster?.autoAcceptKnownPresenceSubscriptionRequests = true
            xmppRoster?.activate(xmppStream)
            xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
    }

    private func setupLastActivity() {
        xmppLastActivity = XMPPLastActivity()
        xmppLastActivity.activate(xmppStream)
        xmppLastActivity.addDelegate(self, delegateQueue: DispatchQueue.main)
    }

    private func setupMAM() {
        xmppMAM = XMPPMessageArchiveManagement()
        xmppMAM?.activate(xmppStream)
        xmppMAM?.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppMAM?.retrieveFormFields()
    }

    // MARK: - Connection
    func connect() {
        guard xmppStream.isDisconnected else {
            printLog("\(#function) | Already connected")
            return
        }
        do {
            try xmppStream.connect(withTimeout: 60.0)
            APP_DELEGATE.objXMPPConnStatus = .Processing
        } catch {
            print("\(#function) | Error connecting: \(error.localizedDescription)")
            APP_DELEGATE.objXMPPConnStatus = .Failed
        }
    }

    func disconnect() {
        changeStatus(.Offline)
        xmppStream.disconnectAfterSending()
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
    }

    func restart() {
        xmppStream.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }

    func isConnected() -> Bool { xmppStream.isConnected }
    func isAuthenticated() -> Bool { xmppStream.isAuthenticated }
    func isSendMessage() -> Bool { isConnected() && isAuthenticated() }

    // MARK: - User/Status helpers
    func getUserId() -> String {
        return xmppStream.myJID?.user?.trim() ?? ""
    }

    func getJIDNameForUser(_ jid: String) -> String {
        let trimmedJid = jid.trim()
        if trimmedJid.contains(hostName) { return trimmedJid }
        return "\(trimmedJid)@\(hostName)"
    }

    func changeStatus(_ status: Status) {
        let type = (status == .Online) ? "available" : "unavailable"
        let presence = XMPPPresence(type: type)
        xmppStream.send(presence)
    }

    func changePresence(mode: String, type: String) {
        let presenceType = (type == "available") ? "available" : "unavailable"
        let presence = XMPPPresence(type: presenceType)
        let showElement = DDXMLElement.element(withName: "show", stringValue: mode) as! DDXMLElement
        presence.addChild(showElement)
        addLogger(.sentMessageToServer, presence)
        xmppStream.send(presence)
    }
}
