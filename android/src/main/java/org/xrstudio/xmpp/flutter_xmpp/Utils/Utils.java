package org.xrstudio.xmpp.flutter_xmpp.Utils;

import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import android.util.Log;

import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smack.util.PacketParserUtils;
import org.jivesoftware.smackx.chatstates.ChatState;
import org.jivesoftware.smackx.chatstates.packet.ChatStateExtension;
import org.jivesoftware.smackx.delay.packet.DelayInformation;
import org.jivesoftware.smackx.pubsub.EventElement;
import org.jivesoftware.smackx.pubsub.ItemsExtension;
import org.jivesoftware.smackx.pubsub.PayloadItem;
import org.jivesoftware.smackx.pubsub.SimplePayload;
import org.jivesoftware.smackx.receipts.DeliveryReceipt;
import org.jxmpp.jid.Jid;
import org.jxmpp.jid.impl.JidCreate;
import org.jxmpp.stringprep.XmppStringprepException;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ErrorState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.SuccessState;
import org.xrstudio.xmpp.flutter_xmpp.FlutterXmppPlugin;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class Utils {

    public static String logFilePath = "";
    private static final String logFileName = "xmpp_logs.txt";

    public static String getValidJid(String jid) {
        if (jid != null && jid.contains(Constants.SYMBOL_COMPARE_JID)) {
            jid = jid.split(Constants.SYMBOL_COMPARE_JID)[0];
        }
        return jid != null ? jid : "";
    }

    public static Jid getFullJid(String jid) {
        if (jid == null || jid.isEmpty()) return null;

        if (!jid.contains(Constants.SYMBOL_COMPARE_JID) && FlutterXmppConnection.mHost != null) {
            jid = jid + "@" + FlutterXmppConnection.mHost;
        }

        try {
            return JidCreate.from(jid);
        } catch (XmppStringprepException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static long getLongDate() {
        return new Date().getTime();
    }

    public static String getJidWithDomainName(String jid, String host) {
        return jid.contains(host) ? jid : jid + Constants.SYMBOL_COMPARE_JID + host;
    }

    public static String getRoomIdWithDomainName(String groupName, String host) {
        if (!groupName.contains(Constants.CONFERENCE)) {
            return groupName + Constants.SYMBOL_COMPARE_JID + Constants.CONFERENCE + Constants.DOT + host;
        }
        return groupName;
    }

    public static void addLogInStorage(String text) {
        if (logFilePath == null || logFilePath.isEmpty()) return;

        text = "Time: " + getTimeMillisecondFormat() + " " + text;
        File logFile = new File(logFilePath);

        if (!logFile.exists()) {
            try {
                logFile.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
                return;
            }
        }

        try (BufferedWriter buf = new BufferedWriter(new FileWriter(logFile, true))) {
            buf.append(text.trim()).append("\n");
            buf.newLine();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void checkDirectoryExist(String directoryName) {
        File dir = new File(Environment.getExternalStorageDirectory(), directoryName);
        if (!dir.exists()) dir.mkdirs();
    }

    public static String getTimeMillisecondFormat() {
        return convertDate(new Date().getTime(), Constants.DATE_FORMAT);
    }

    public static String convertDate(long dateToConvert, String format) {
        return new SimpleDateFormat(format, Locale.getDefault()).format(new Date(dateToConvert));
    }

    public static boolean validIP(String ip) {
        if (ip == null || ip.isEmpty()) return false;
        String[] parts = ip.split("\\.");
        if (parts.length != 4) return false;

        try {
            for (String s : parts) {
                int i = Integer.parseInt(s);
                if (i < 0 || i > 255) return false;
            }
            return !ip.endsWith(Constants.DOT);
        } catch (NumberFormatException e) {
            return false;
        }
    }

    public static void printLog(String message) {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(Constants.TAG, message);
        }
    }

    public static void broadcastMessageToFlutter(Context context, Message message) {

        addLogInStorage("Action: receiveMessageFromServer, Content: " + message.toXML());

        message = parseEventStanzaMessage(message);
        String metaText = Constants.MESSAGE;
        String body = message.getBody();
        String from = message.getFrom().toString();
        String msgId = message.getStanzaId();
        String customText = "";

        StandardExtensionElement customElement = (StandardExtensionElement) message
                .getExtension(Constants.URN_XMPP_CUSTOM);
        if (customElement != null && customElement.getFirstElement(Constants.custom) != null) {
            customText = customElement.getFirstElement(Constants.custom).getText();
        }

        String time = Constants.ZERO;
        if (message.getExtension(Constants.URN_XMPP_TIME) != null) {
            StandardExtensionElement timeElement = (StandardExtensionElement) message
                    .getExtension(Constants.URN_XMPP_TIME);
            if (timeElement != null && timeElement.getFirstElement(Constants.TS) != null) {
                time = timeElement.getFirstElement(Constants.TS).getText();
            }
        }

        if (message.hasExtension(DeliveryReceipt.ELEMENT, DeliveryReceipt.NAMESPACE)) {
            DeliveryReceipt dr = DeliveryReceipt.from(message);
            msgId = dr.getId();
            metaText = Constants.DELIVERY_ACK;
        }

        ChatState chatState = null;
        if (message.hasExtension(ChatStateExtension.NAMESPACE)) {
            metaText = Constants.CHATSTATE;
            ChatStateExtension chatStateExtension = (ChatStateExtension) message.getExtension(ChatStateExtension.NAMESPACE);
            chatState = chatStateExtension.getChatState();
        }

        String delayTime = Constants.ZERO;
        if (message.hasExtension(Constants.URN_XMPP_RECEIPTS)) {
            DelayInformation delayInfo = (DelayInformation) message.getExtension(Constants.URN_XMPP_DELAY);
            if (delayInfo != null && delayInfo.getStamp() != null) {
                delayTime = delayInfo.getStamp().toString();
            }
        }

        if (!from.equals(FlutterXmppConnection.mUsername)) {
            Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
            intent.setPackage(context.getPackageName());
            intent.putExtra(Constants.BUNDLE_FROM_JID, from);
            intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, body);
            intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, msgId);
            intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, message.getType().toString());
            intent.putExtra(Constants.BUNDLE_MESSAGE_SENDER_JID, from);
            intent.putExtra(Constants.CUSTOM_TEXT, customText);
            intent.putExtra(Constants.META_TEXT, metaText);
            intent.putExtra(Constants.time, time);
            intent.putExtra(Constants.DELAY_TIME, delayTime);
            if (chatState != null) {
                intent.putExtra(Constants.CHATSTATE_TYPE, chatState.toString().toLowerCase());
            }
            context.sendBroadcast(intent);
        }
    }

    private static Message parseEventStanzaMessage(Message message) {
        try {
            EventElement eventElement = message.getExtension(Constants.event, Constants.eventPubSubNameSpace);
            if (eventElement != null) {
                List<ExtensionElement> itemExtensions = eventElement.getExtensions();
                for (ExtensionElement ext : itemExtensions) {
                    ItemsExtension itemsExtension = (ItemsExtension) ext;
                    List<?> items = itemsExtension.getItems();
                    for (Object obj : items) {
                        PayloadItem<?> payloadItem = (PayloadItem<?>) obj;
                        SimplePayload payload = (SimplePayload) payloadItem.getPayload();
                        message = (Message) PacketParserUtils.parseStanza((String) payload.toXML());
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return message;
    }

    public static void broadcastSuccessMessageToFlutter(Context context, SuccessState state, String jid) {
        Intent intent = new Intent(Constants.SUCCESS_MESSAGE);
        intent.setPackage(context.getPackageName());
        intent.putExtra(Constants.BUNDLE_SUCCESS_TYPE, state.toString());
        intent.putExtra(Constants.FROM, jid);
        context.sendBroadcast(intent);
    }

    public static void broadcastErrorMessageToFlutter(Context context, ErrorState state, String exception, String jid) {
        Intent intent = new Intent(Constants.ERROR_MESSAGE);
        intent.setPackage(context.getPackageName());
        intent.putExtra(Constants.FROM, jid);
        intent.putExtra(Constants.BUNDLE_EXCEPTION, exception);
        intent.putExtra(Constants.BUNDLE_ERROR_TYPE, state.toString());
        context.sendBroadcast(intent);
    }

    public static void broadcastConnectionMessageToFlutter(Context context, ConnectionState state, String errorMessage) {
        Intent intent = new Intent(Constants.CONNECTION_STATE_MESSAGE);
        intent.setPackage(context.getPackageName());
        intent.putExtra(Constants.BUNDLE_CONNECTION_TYPE, state.toString());
        intent.putExtra(Constants.BUNDLE_CONNECTION_ERROR, errorMessage);
        context.sendBroadcast(intent);
    }
}
