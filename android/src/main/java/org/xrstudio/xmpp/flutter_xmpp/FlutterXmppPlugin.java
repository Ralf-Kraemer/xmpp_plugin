package org.xrstudio.xmpp.flutter_xmpp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.LifecycleOwner;

import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.XMPPException;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnectionService;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.GroupRole;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;
import org.xrstudio.xmpp.flutter_xmpp.managers.MAMManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterXmppPlugin implements MethodChannel.MethodCallHandler,
        FlutterPlugin, ActivityAware, EventChannel.StreamHandler, DefaultLifecycleObserver {

    public static final boolean DEBUG = true;

    private Context applicationContext;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel successChannel;
    private EventChannel errorChannel;
    private EventChannel connectionChannel;

    private BroadcastReceiver messageReceiver;
    private BroadcastReceiver successReceiver;
    private BroadcastReceiver errorReceiver;
    private BroadcastReceiver connectionReceiver;

    private String jidUser = "";
    private String password = "";
    private String host = "";
    private boolean requireSSL = false;
    private boolean autoDeliveryReceipt = false;
    private boolean automaticReconnection = true;
    private boolean useStreamManagement = true;

    private ExecutorService executorService = Executors.newSingleThreadExecutor();

    // ---------- BroadcastReceiver Helpers ----------

    private BroadcastReceiver createMessageReceiver(final EventChannel.EventSink events) {
        return intent -> {
            if (intent == null || events == null) return;

            String action = intent.getAction();
            if (action == null) return;

            Map<String, Object> build = new HashMap<>();

            switch (action) {
                case Constants.CONNECTION_MESSAGE:
                    build.put(Constants.TYPE, Constants.CONNECTION);
                    build.put(Constants.STATUS, Constants.connected);
                    Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + build.toString());
                    events.success(build);
                    break;

                case Constants.AUTH_MESSAGE:
                    build.put(Constants.TYPE, Constants.CONNECTION);
                    build.put(Constants.STATUS, Constants.authenticated);
                    Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + build.toString());
                    events.success(build);
                    break;

                case Constants.RECEIVE_MESSAGE:
                    build.put(Constants.TYPE, intent.getStringExtra(Constants.META_TEXT));
                    build.put(Constants.ID, intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS));
                    build.put(Constants.FROM, intent.getStringExtra(Constants.BUNDLE_FROM_JID));
                    build.put(Constants.BODY, intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY));
                    build.put(Constants.MSG_TYPE, intent.getStringExtra(Constants.BUNDLE_MESSAGE_TYPE));
                    build.put(Constants.SENDER_JID, intent.getStringExtra(Constants.BUNDLE_MESSAGE_SENDER_JID));
                    build.put(Constants.CUSTOM_TEXT, intent.getStringExtra(Constants.CUSTOM_TEXT));
                    build.put(Constants.time, intent.getStringExtra(Constants.time));
                    build.put(Constants.CHATSTATE_TYPE, intent.getStringExtra(Constants.CHATSTATE_TYPE));
                    build.put(Constants.DELAY_TIME, intent.getStringExtra(Constants.DELAY_TIME));
                    Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + build.toString());
                    events.success(build);
                    break;

                case Constants.OUTGOING_MESSAGE:
                    build.put(Constants.TYPE, Constants.OUTGOING);
                    build.put(Constants.ID, intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS));
                    build.put(Constants.TO, intent.getStringExtra(Constants.BUNDLE_TO_JID));
                    build.put(Constants.BODY, intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY));
                    build.put(Constants.MSG_TYPE, intent.getStringExtra(Constants.BUNDLE_MESSAGE_TYPE));
                    events.success(build);
                    break;

                case Constants.PRESENCE_MESSAGE:
                    build.put(Constants.TYPE, Constants.PRESENCE);
                    build.put(Constants.FROM, intent.getStringExtra(Constants.BUNDLE_FROM_JID));
                    build.put(Constants.PRESENCE_TYPE, intent.getStringExtra(Constants.BUNDLE_PRESENCE_TYPE));
                    build.put(Constants.PRESENCE_MODE, intent.getStringExtra(Constants.BUNDLE_PRESENCE_MODE));
                    Utils.printLog("presenceBuild: " + build);
                    events.success(build);
                    break;
            }
        };
    }

    private BroadcastReceiver createSimpleReceiver(final EventChannel.EventSink events, String actionKey) {
        return intent -> {
            if (intent == null || events == null) return;
            if (!actionKey.equals(intent.getAction())) return;

            Map<String, Object> build = new HashMap<>();
            switch (actionKey) {
                case Constants.SUCCESS_MESSAGE:
                    build.put(Constants.TYPE, intent.getStringExtra(Constants.BUNDLE_SUCCESS_TYPE));
                    build.put(Constants.FROM, intent.getStringExtra(Constants.FROM));
                    break;
                case Constants.ERROR_MESSAGE:
                    build.put(Constants.FROM, intent.getStringExtra(Constants.FROM));
                    build.put(Constants.EXCEPTION, intent.getStringExtra(Constants.BUNDLE_EXCEPTION));
                    build.put(Constants.TYPE, intent.getStringExtra(Constants.BUNDLE_ERROR_TYPE));
                    break;
                case Constants.CONNECTION_STATE_MESSAGE:
                    build.put(Constants.TYPE, intent.getStringExtra(Constants.BUNDLE_CONNECTION_TYPE));
                    build.put(Constants.ERROR, intent.getStringExtra(Constants.BUNDLE_CONNECTION_ERROR));
                    break;
            }
            Utils.addLogInStorage("Action: broadcastToFlutter, Content: " + build);
            events.success(build);
        };
    }

    // ---------- Lifecycle Methods ----------

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = binding.getApplicationContext();
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), Constants.CHANNEL);
        methodChannel.setMethodCallHandler(this);

        eventChannel = new EventChannel(binding.getBinaryMessenger(), Constants.CHANNEL_STREAM);
        eventChannel.setStreamHandler(this);

        successChannel = new EventChannel(binding.getBinaryMessenger(), Constants.CHANNEL_SUCCESS_EVENT_STREAM);
        errorChannel = new EventChannel(binding.getBinaryMessenger(), Constants.CHANNEL_ERROR_EVENT_STREAM);
        connectionChannel = new EventChannel(binding.getBinaryMessenger(), Constants.CHANNEL_CONNECTION_EVENT_STREAM);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        unregisterAllReceivers();
        Utils.printLog("FlutterXmppPlugin detached from engine");
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        applicationContext = binding.getActivity().getApplicationContext();
    }

    @Override
    public void onDetachedFromActivity() { }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        applicationContext = binding.getActivity().getApplicationContext();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() { }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        executorService.execute(() -> {
            try {
                FlutterXmppConnection.reconnect();
            } catch (Exception e) {
                Utils.printLog("Reconnect failed: " + e.getMessage());
            }
        });
        checkAndReconnect();
    }

    // ---------- StreamHandler ----------

    @Override
    public void onListen(Object args, EventChannel.EventSink events) {
        if (messageReceiver == null) {
            messageReceiver = createMessageReceiver(events);
            IntentFilter filter = new IntentFilter();
            filter.addAction(Constants.RECEIVE_MESSAGE);
            filter.addAction(Constants.OUTGOING_MESSAGE);
            filter.addAction(Constants.PRESENCE_MESSAGE);
            applicationContext.registerReceiver(messageReceiver, filter, Context.RECEIVER_EXPORTED);
        }
    }

    @Override
    public void onCancel(Object args) {
        if (messageReceiver != null) {
            applicationContext.unregisterReceiver(messageReceiver);
            messageReceiver = null;
        }
    }

    // ---------- Utility Methods ----------

    private void unregisterAllReceivers() {
        try {
            if (messageReceiver != null) applicationContext.unregisterReceiver(messageReceiver);
            if (successReceiver != null) applicationContext.unregisterReceiver(successReceiver);
            if (errorReceiver != null) applicationContext.unregisterReceiver(errorReceiver);
            if (connectionReceiver != null) applicationContext.unregisterReceiver(connectionReceiver);
        } catch (Exception ignored) {}
        messageReceiver = successReceiver = errorReceiver = connectionReceiver = null;
    }

    private void checkAndReconnect() {
        if (jidUser == null || password == null || jidUser.isEmpty() || password.isEmpty()) return;

        ConnectionState state = FlutterXmppConnectionService.getState();
        if (state == ConnectionState.DISCONNECTED || state == ConnectionState.FAILED) {
            Utils.broadcastConnectionMessageToFlutter(applicationContext, ConnectionState.CONNECTING, "Connecting to chat server");
            Intent i = new Intent(applicationContext, FlutterXmppConnectionService.class);
            i.putExtra(Constants.JID_USER, jidUser);
            i.putExtra(Constants.PASSWORD, password);
            i.putExtra(Constants.HOST, host);
            i.putExtra(Constants.PORT, Constants.PORT_NUMBER);
            i.putExtra(Constants.AUTO_DELIVERY_RECEIPT, autoDeliveryReceipt);
            i.putExtra(Constants.REQUIRE_SSL_CONNECTION, requireSSL);
            i.putExtra(Constants.USER_STREAM_MANAGEMENT, useStreamManagement);
            i.putExtra(Constants.AUTOMATIC_RECONNECTION, automaticReconnection);
            applicationContext.startService(i);
        }
    }

}
