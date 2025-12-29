package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.content.Intent;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class StanzaAckListener implements StanzaListener {

    private final Context applicationContext;

    public StanzaAckListener(Context context) {
        // Use application context to avoid memory leaks
        this.applicationContext = context != null ? context.getApplicationContext() : null;
    }

    @Override
    public void processStanza(Stanza stanza) {
        if (!(stanza instanceof Message) || applicationContext == null) {
            return;
        }

        Message ackMessage = (Message) stanza;

        Utils.addLogInStorage("Action: receiveStanzaAckFromServer, Content: " + ackMessage.toXML().toString());

        String time = Constants.ZERO;
        if (ackMessage.getExtension(Constants.URN_XMPP_TIME) instanceof StandardExtensionElement timeElement) {
            if (timeElement.getFirstElement(Constants.TS) != null) {
                time = timeElement.getFirstElement(Constants.TS).getText();
            }
        }

        // Broadcast the ACK message
        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
        intent.setPackage(applicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, ackMessage.getTo() != null ? ackMessage.getTo().toString() : "");
        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, ackMessage.getBody() != null ? ackMessage.getBody() : "");
        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, ackMessage.getStanzaId() != null ? ackMessage.getStanzaId() : "");
        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, ackMessage.getType() != null ? ackMessage.getType().toString() : "");
        intent.putExtra(Constants.META_TEXT, Constants.ACK);
        intent.putExtra(Constants.time, time);

        applicationContext.sendBroadcast(intent);
    }
}
