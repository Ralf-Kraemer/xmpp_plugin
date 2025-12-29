package org.xrstudio.xmpp.flutter_xmpp.managers;

import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.tcp.XMPPTCPConnection;
import org.jivesoftware.smackx.mam.MamManager;
import org.jxmpp.jid.Jid;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

import java.util.Date;
import java.util.List;

public class MAMManager {

    public static void requestMAM(String userJid, String requestBefore, String requestSince, String limit) {
        XMPPTCPConnection connection = FlutterXmppConnection.getConnection();

        if (connection == null || !connection.isAuthenticated()) {
            Utils.printLog("MAM request failed: connection is null or not authenticated");
            return;
        }

        try {
            MamManager mamManager = MamManager.getInstanceFor(connection);
            MamManager.MamQueryArgs.Builder queryArgs = MamManager.MamQueryArgs.builder();

            // Handle 'before' timestamp
            if (requestBefore != null && !requestBefore.isEmpty()) {
                try {
                    long requestBeforeTs = Long.parseLong(requestBefore);
                    if (requestBeforeTs > 0) {
                        queryArgs.limitResultsBefore(new Date(requestBeforeTs));
                    }
                } catch (NumberFormatException ignored) {
                    Utils.printLog("Invalid requestBefore timestamp: " + requestBefore);
                }
            }

            // Handle 'since' timestamp
            if (requestSince != null && !requestSince.isEmpty()) {
                try {
                    long requestSinceTs = Long.parseLong(requestSince);
                    if (requestSinceTs > 0) {
                        queryArgs.limitResultsSince(new Date(requestSinceTs));
                    }
                } catch (NumberFormatException ignored) {
                    Utils.printLog("Invalid requestSince timestamp: " + requestSince);
                }
            }

            // Handle limit
            if (limit != null && !limit.isEmpty()) {
                try {
                    int limitMessage = Integer.parseInt(limit);
                    queryArgs.setResultPageSizeTo(limitMessage > 0 ? limitMessage : Integer.MAX_VALUE);
                } catch (NumberFormatException ignored) {
                    Utils.printLog("Invalid limit value: " + limit);
                    queryArgs.setResultPageSizeTo(Integer.MAX_VALUE);
                }
            }

            // Handle user JID
            userJid = Utils.getValidJid(userJid);
            if (userJid != null && !userJid.isEmpty()) {
                Jid jid = Utils.getFullJid(userJid);
                if (jid != null) {
                    queryArgs.limitResultsToJid(jid);
                }
            }

            Utils.printLog("MAM query Args: " + queryArgs.toString());

            MamManager.MamQuery query = mamManager.queryArchive(queryArgs.build());
            List<Message> messageList = query.getMessages();

            if (messageList != null) {
                for (Message message : messageList) {
                    Utils.printLog("Received Message: " + message.toXML());
                    Utils.broadcastMessageToFlutter(FlutterXmppConnection.getApplicationContext(), message);
                }
            }

        } catch (Exception e) {
            Utils.printLog("Error during MAM request: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
