package org.xrstudio.xmpp.flutter_xmpp.Connection;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import org.jivesoftware.smack.*;
import org.jivesoftware.smack.filter.StanzaTypeFilter;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Presence;
import org.jivesoftware.smack.roster.Roster;
import org.jivesoftware.smack.tcp.XMPPTCPConnection;
import org.jivesoftware.smack.tcp.XMPPTCPConnectionConfiguration;
import org.jivesoftware.smackx.chatstates.ChatState;
import org.jivesoftware.smackx.chatstates.packet.ChatStateExtension;
import org.jivesoftware.smackx.iqlast.LastActivityManager;
import org.jivesoftware.smackx.iqlast.packet.LastActivity;
import org.jivesoftware.smackx.mam.MamManager;
import org.jivesoftware.smackx.mam.MamQueryResult;
import org.jivesoftware.smackx.mam.element.MamElements;
import org.jivesoftware.smackx.muc.*;
import org.jivesoftware.smackx.receipts.DeliveryReceipt;
import org.jivesoftware.smackx.receipts.DeliveryReceiptRequest;
import org.jivesoftware.smackx.forward.Forwarded;
import org.jxmpp.jid.EntityBareJid;
import org.jxmpp.jid.Jid;
import org.jxmpp.jid.impl.JidCreate;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.GroupRole;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;
import org.xrstudio.xmpp.flutter_xmpp.listner.MessageListener;
import org.xrstudio.xmpp.flutter_xmpp.listner.PresenceListenerAndFilter;
import org.xrstudio.xmpp.flutter_xmpp.listner.StanzaAckListener;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import java.io.IOException;
import java.net.InetAddress;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FlutterXmppConnection implements ConnectionListener {

    private static String mHost;
    private static String mUsername = "";
    private static String mPassword;
    private static String mResource = "";
    private static String mServiceName = "";
    private static Roster rosterConnection;
    private static XMPPTCPConnection mConnection;
    private static MultiUserChatManager multiUserChatManager;
    private static boolean mRequireSSLConnection, mAutoDeliveryReceipt, mAutomaticReconnection = true, mUseStreamManagement = true;
    private static Context mApplicationContext;

    private ReconnectionManager reconnectionManager;
    private BroadcastReceiver uiThreadMessageReceiver;

    public FlutterXmppConnection(Context context, String jidUser, String password, String host, int port,
                                boolean requireSSLConnection, boolean autoDeliveryReceipt,
                                boolean useStreamManagement, boolean automaticReconnection) {

        Utils.printLog("Connection Constructor called");

        mApplicationContext = context.getApplicationContext();
        mPassword = password;
        Constants.PORT_NUMBER = port;
        mHost = host;
        mRequireSSLConnection = requireSSLConnection;
        mAutoDeliveryReceipt = autoDeliveryReceipt;
        mUseStreamManagement = useStreamManagement;
        mAutomaticReconnection = automaticReconnection;

        if (jidUser != null && jidUser.contains(Constants.SYMBOL_COMPARE_JID)) {
            String[] jidParts = jidUser.split(Constants.SYMBOL_COMPARE_JID);
            mUsername = jidParts[0];

            if (jidParts[1].contains(Constants.SYMBOL_FORWARD_SLASH)) {
                String[] domainResource = jidParts[1].split(Constants.SYMBOL_FORWARD_SLASH);
                mServiceName = domainResource[0];
                mResource = domainResource[1];
            } else {
                mServiceName = jidParts[1];
                mResource = Constants.ANDROID;
            }
            mResource = System.currentTimeMillis() + mResource;
        }
    }

    public static Context getApplicationContext() {
        return mApplicationContext;
    }

    public static XMPPTCPConnection getConnection() {
        return mConnection != null ? mConnection : null;
    }

    // ------------------ Sending Messages ------------------
    public static void sendCustomMessage(String body, String toJid, String msgId, String customText, boolean isDm, String time) {
        try {
            if (mConnection == null || !mConnection.isConnected()) return;

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);
            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);

            if (mAutoDeliveryReceipt) DeliveryReceiptRequest.addTo(xmppMessage);
            xmppMessage.addExtension(Utils.createTimeElement(time));
            xmppMessage.addExtension(Utils.createCustomElement(customText));

            if (isDm) {
                xmppMessage.setTo(JidCreate.from(toJid));
                mConnection.sendStanza(xmppMessage);
            } else {
                EntityBareJid mucJid = JidCreate.bareFrom(Utils.getRoomIdWithDomainName(toJid, mHost));
                MultiUserChat muc = multiUserChatManager.getMultiUserChat(mucJid);
                muc.sendMessage(xmppMessage);
            }

            Utils.addLogInStorage("Action: sentCustomMessageToServer, Content: " + xmppMessage.toXML());
            Utils.printLog("Sent custom message: " + xmppMessage.toXML());

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ------------------ Multi-User Chat Management ------------------
    public static void manageAddMembersInGroup(GroupRole role, String groupName, List<String> membersJid) {
        try {
            MultiUserChat muc = multiUserChatManager.getMultiUserChat(
                    JidCreate.entityBareFrom(Utils.getRoomIdWithDomainName(groupName, mHost)));

            for (int i = 0; i < membersJid.size(); i++) {
                String member = membersJid.get(i);
                if (!member.contains(mHost)) member += Constants.SYMBOL_COMPARE_JID + mHost;
                membersJid.set(i, member);
            }

            if (role == GroupRole.ADMIN) muc.grantAdmin(Utils.toJidList(membersJid));
            else if (role == GroupRole.MEMBER) muc.grantMembership(Utils.toJidList(membersJid));

            for (Jid jid : Utils.toJidList(membersJid)) muc.invite(jid.asEntityBareJidIfPossible(), Constants.INVITE_MESSAGE);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ------------------ Request Archived Messages ------------------
    public List<Map<String, String>> requestArchivedMessages() {
        List<Map<String, String>> archivedMessages = new ArrayList<>();
        try {
            if (mConnection == null || !mConnection.isConnected()) return archivedMessages;

            MamManager mamManager = MamManager.getInstanceFor(mConnection);
            MamQueryResult mamResult = mamManager.queryArchive(null, null);

            for (Forwarded forwarded : mamResult.getForwardedMessages()) {
                Message message = (Message) forwarded.getForwardedStanza();
                Map<String, String> map = new HashMap<>();
                map.put("id", message.getStanzaId());
                map.put("body", message.getBody());
                map.put("from", message.getFrom().toString());
                map.put("to", message.getTo().toString());
                map.put("type", message.getType().name());
                archivedMessages.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return archivedMessages;
    }

    // ------------------ Connection Lifecycle ------------------
    public void connect() throws IOException, XMPPException, SmackException {
        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTING;

        XMPPTCPConnectionConfiguration.Builder conf = XMPPTCPConnectionConfiguration.builder();
        conf.setXmppDomain(mServiceName);

        if (Utils.validIP(mHost)) {
            InetAddress address = InetAddress.getByName(mHost);
            conf.setHostAddress(address).setHost(mHost);
        } else conf.setHost(mHost);

        if (Constants.PORT_NUMBER != 0) conf.setPort(Constants.PORT_NUMBER);

        conf.setUsernameAndPassword(mUsername, mPassword);
        conf.setResource(mResource);
        conf.setCompressionEnabled(true);
        conf.enableDefaultDebugger();

        if (mRequireSSLConnection) {
            try {
                SSLContext context = SSLContext.getInstance(Constants.TLS);
                context.init(null, new TrustManager[]{new Utils.AcceptAllTrustManager()}, new SecureRandom());
                conf.setCustomSSLContext(context);
                conf.setKeystoreType(null);
                conf.setSecurityMode(ConnectionConfiguration.SecurityMode.required);
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else conf.setSecurityMode(ConnectionConfiguration.SecurityMode.disabled);

        mConnection = new XMPPTCPConnection(conf.build());
        mConnection.addConnectionListener(this);
        mConnection.connect();
        mConnection.login();

        rosterConnection = Roster.getInstanceFor(mConnection);
        rosterConnection.setSubscriptionMode(Roster.SubscriptionMode.accept_all);

        if (mUseStreamManagement) {
            mConnection.setUseStreamManagement(true);
            mConnection.setUseStreamManagementResumption(true);
        }

        setupUiThreadBroadcastReceiver();

        mConnection.addSyncStanzaListener(new PresenceListenerAndFilter(mApplicationContext), StanzaTypeFilter.PRESENCE);
        mConnection.addStanzaAcknowledgedListener(new StanzaAckListener(mApplicationContext));
        mConnection.addSyncStanzaListener(new MessageListener(mApplicationContext), StanzaTypeFilter.MESSAGE);

        if (mAutomaticReconnection) {
            ReconnectionManager.getInstanceFor(mConnection).enableAutomaticReconnection();
        }
    }

    public void disconnect() {
        Utils.printLog("Disconnecting from server: " + mServiceName);
        if (mConnection != null) {
            mConnection.disconnect();
            mConnection = null;
        }
        if (uiThreadMessageReceiver != null) {
            try {
                mApplicationContext.unregisterReceiver(uiThreadMessageReceiver);
            } catch (Exception ignored) {}
            uiThreadMessageReceiver = null;
        }
    }

    @Override
    public void connected(XMPPConnection connection) {
        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTED;
        Utils.broadcastConnectionMessageToFlutter(mApplicationContext, ConnectionState.CONNECTED, "");
    }

    @Override
    public void authenticated(XMPPConnection connection, boolean resumed) {
        multiUserChatManager = MultiUserChatManager.getInstanceFor(connection);
        FlutterXmppConnectionService.sConnectionState = ConnectionState.AUTHENTICATED;
        Utils.broadcastConnectionMessageToFlutter(mApplicationContext, ConnectionState.AUTHENTICATED, "");
    }

    @Override
    public void connectionClosed() {
        FlutterXmppConnectionService.sConnectionState = ConnectionState.DISCONNECTED;
        Utils.broadcastConnectionMessageToFlutter(mApplicationContext, ConnectionState.DISCONNECTED, "");
    }

    @Override
    public void connectionClosedOnError(Exception e) {
        FlutterXmppConnectionService.sConnectionState = ConnectionState.FAILED;
        if (uiThreadMessageReceiver != null) {
            try {
                mApplicationContext.unregisterReceiver(uiThreadMessageReceiver);
            } catch (Exception ignored) {}
            uiThreadMessageReceiver = null;
        }
        Utils.broadcastConnectionMessageToFlutter(mApplicationContext, ConnectionState.FAILED, e.getLocalizedMessage());
    }

    // ------------------ Helpers ------------------
    private void setupUiThreadBroadcastReceiver() {
        uiThreadMessageReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (action.equals(Constants.X_SEND_MESSAGE) || action.equals(Constants.GROUP_SEND_MESSAGE)) {
                    sendMessage(
                            intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY),
                            intent.getStringExtra(Constants.BUNDLE_TO),
                            intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS),
                            action.equals(Constants.X_SEND_MESSAGE),
                            intent.getStringExtra(Constants.BUNDLE_MESSAGE_SENDER_TIME)
                    );
                }
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(Constants.X_SEND_MESSAGE);
        filter.addAction(Constants.GROUP_SEND_MESSAGE);
        mApplicationContext.registerReceiver(uiThreadMessageReceiver, filter, Context.RECEIVER_EXPORTED);
    }

    private void sendMessage(String body, String toJid, String msgId, boolean isDm, String time) {
        try {
            if (mConnection == null || !mConnection.isConnected()) return;

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);
            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);

            if (mAutoDeliveryReceipt) DeliveryReceiptRequest.addTo(xmppMessage);
            xmppMessage.addExtension(Utils.createTimeElement(time));

            if (isDm) {
                xmppMessage.setTo(JidCreate.from(toJid));
                mConnection.sendStanza(xmppMessage);
            } else {
                EntityBareJid mucJid = JidCreate.bareFrom(Utils.getRoomIdWithDomainName(toJid, mHost));
                MultiUserChat muc = multiUserChatManager.getMultiUserChat(mucJid);
                muc.sendMessage(xmppMessage);
            }

            Utils.addLogInStorage("Action: sentMessageToServer, Content: " + xmppMessage.toXML());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
