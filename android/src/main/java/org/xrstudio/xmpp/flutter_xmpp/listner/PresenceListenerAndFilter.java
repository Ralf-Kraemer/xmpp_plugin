package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.content.Intent;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Presence;
import org.jivesoftware.smack.packet.Stanza;
import org.jivesoftware.smackx.muc.packet.MUCUser;
import org.xrstudio.xmpp.flutter_xmpp.Enum.SuccessState;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class PresenceListenerAndFilter implements StanzaListener {

    private final Context applicationContext;

    public PresenceListenerAndFilter(Context context) {
        // Use application context to prevent memory leaks
        this.applicationContext = context != null ? context.getApplicationContext() : null;
    }

    @Override
    public void processStanza(Stanza stanza) {
        if (!(stanza instanceof Presence) || applicationContext == null) {
            return;
        }

        Presence presence = (Presence) stanza;
        String jid = presence.getFrom() != null ? presence.getFrom().toString() : "";
        Presence.Type type = presence.getType() != null ? presence.getType() : Presence.Type.available;
        Presence.Mode mode = presence.getMode() != null ? presence.getMode() : Presence.Mode.available;

        // Handle MUC (group chat) presence extensions
        if (presence.hasExtension(MUCUser.ELEMENT, MUCUser.NAMESPACE)) {
            MUCUser mucUser = MUCUser.from(presence);

            if (mucUser != null && mucUser.getStatus() != null) {
                if (mucUser.getStatus().contains(MUCUser.Status.ROOM_CREATED_201)) {
                    Utils.broadcastSuccessMessageToFlutter(applicationContext, SuccessState.GROUP_CREATED_SUCCESS, jid);
                    return;
                } else if (mucUser.getStatus().contains(MUCUser.Status.PRESENCE_TO_SELF_110)) {
                    Utils.broadcastSuccessMessageToFlutter(applicationContext, SuccessState.GROUP_JOINED_SUCCESS, jid);
                    return;
                }
            }
        }

        // Broadcast regular presence updates
        Intent intent = new Intent(Constants.PRESENCE_MESSAGE);
        intent.setPackage(applicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, jid);
        intent.putExtra(Constants.BUNDLE_PRESENCE_TYPE, type.toString().toLowerCase());
        intent.putExtra(Constants.BUNDLE_PRESENCE_MODE, mode.toString().toLowerCase());
        applicationContext.sendBroadcast(intent);
    }
}
