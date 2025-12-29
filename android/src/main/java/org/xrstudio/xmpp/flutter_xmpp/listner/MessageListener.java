package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class MessageListener implements StanzaListener {

    private final Context applicationContext;

    public MessageListener(Context context) {
        // Use application context to avoid leaking activity context
        this.applicationContext = context != null ? context.getApplicationContext() : null;
    }

    @Override
    public void processStanza(Stanza stanza) {
        if (stanza instanceof Message && applicationContext != null) {
            Utils.broadcastMessageToFlutter(applicationContext, (Message) stanza);
        }
    }
}
