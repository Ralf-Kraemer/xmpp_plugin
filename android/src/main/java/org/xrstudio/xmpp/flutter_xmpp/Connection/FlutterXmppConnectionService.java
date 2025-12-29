package org.xrstudio.xmpp.flutter_xmpp.Connection;

import android.app.Service;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.XMPPException;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.LoggedInState;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

import java.io.IOException;

public class FlutterXmppConnectionService extends Service {

    // Static states accessible from plugin
    public static LoggedInState sLoggedInState = LoggedInState.LOGGED_OUT;
    public static ConnectionState sConnectionState = ConnectionState.DISCONNECTED;

    private String jidUser = "";
    private String password = "";
    private String host = "";
    private int port = 5222;
    private boolean requireSSLConnection = false;
    private boolean autoDeliveryReceipt = false;
    private boolean useStreamManagement = true;
    private boolean automaticReconnection = true;

    private FlutterXmppConnection mConnection;
    private Thread mThread;
    private Handler mHandler;
    private volatile boolean mActive = false;

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public static ConnectionState getState() {
        return sConnectionState;
    }

    public static LoggedInState getLoggedInState() {
        return sLoggedInState;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Utils.printLog("FlutterXmppConnectionService onCreate()");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Utils.printLog("FlutterXmppConnectionService onStartCommand()");

        if (intent != null && intent.getExtras() != null) {
            Bundle extras = intent.getExtras();
            jidUser = extras.getString(Constants.JID_USER, "");
            password = extras.getString(Constants.PASSWORD, "");
            host = extras.getString(Constants.HOST, "");
            port = extras.getInt(Constants.PORT, 5222);
            requireSSLConnection = extras.getBoolean(Constants.REQUIRE_SSL_CONNECTION, false);
            autoDeliveryReceipt = extras.getBoolean(Constants.AUTO_DELIVERY_RECEIPT, false);
            useStreamManagement = extras.getBoolean(Constants.USER_STREAM_MANAGEMENT, true);
            automaticReconnection = extras.getBoolean(Constants.AUTOMATIC_RECONNECTION, true);
        } else {
            Utils.printLog("Missing connection parameters (JID/User/Password/Host/Port).");
        }

        startConnection();
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        Utils.printLog("FlutterXmppConnectionService onDestroy()");
        stopConnection();
        super.onDestroy();
    }

    // ------------------ Connection Management ------------------
    private void startConnection() {
        Utils.printLog("Starting XMPP Service connection...");

        if (mActive) return;
        mActive = true;

        if (mThread == null || !mThread.isAlive()) {
            mThread = new Thread(() -> {
                Looper.prepare();
                mHandler = new Handler(Looper.myLooper());
                initConnection();
                Looper.loop();
            }, "XMPP-Service-Thread");
            mThread.start();
        }
    }

    private void stopConnection() {
        Utils.printLog("Stopping XMPP Service connection...");
        mActive = false;

        if (mHandler != null) {
            mHandler.post(() -> {
                if (mConnection != null) {
                    mConnection.disconnect();
                    mConnection = null;
                }
            });
        }
    }

    private void initConnection() {
        try {
            Utils.printLog("Initializing XMPP connection...");

            if (mConnection == null) {
                mConnection = new FlutterXmppConnection(
                        this,
                        jidUser,
                        password,
                        host,
                        port,
                        requireSSLConnection,
                        autoDeliveryReceipt,
                        useStreamManagement,
                        automaticReconnection
                );
            }

            mConnection.connect();

        } catch (IOException | SmackException | XMPPException e) {
            sConnectionState = ConnectionState.FAILED;
            Utils.broadcastConnectionMessageToFlutter(
                    this,
                    ConnectionState.FAILED,
                    "Failed to connect: check credentials and server settings."
            );
            Utils.printLog("Failed to initialize XMPP connection.");
            e.printStackTrace();
            stopSelf();
        }
    }
}
