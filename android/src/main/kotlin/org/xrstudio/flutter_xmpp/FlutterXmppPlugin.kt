package org.xrstudio.flutter_xmpp

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.jivesoftware.smack.XMPPConnection
import org.jivesoftware.smackx.carbons.CarbonManager

/** FlutterXmppPlugin */
class FlutterXmppPlugin: FlutterPlugin, MethodCallHandler {

    /// MethodChannel for communication
    private lateinit var channel : MethodChannel

    /// Keep a reference to the active XMPP connection
    private var xmppConnection: XMPPConnection? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_xmpp")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")

            "enableMessageCarbons" -> {
                try {
                    enableMessageCarbons()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CARBONS_ERROR", e.message, null)
                }
            }

            // You can add more XMPP-related method handlers here
            else -> result.notImplemented()
        }
    }

    /**
     * Enable XMPP Message Carbons (XEP-0280) on the active connection
     */
    private fun enableMessageCarbons() {
        val connection = xmppConnection
            ?: throw IllegalStateException("XMPP connection is not initialized")
        val carbonsManager = CarbonManager.getInstance(connection)
        carbonsManager.enableCarbons() // sends <enable xmlns='urn:xmpp:carbons:2'/>
    }

    /**
     * Optional: provide a method to set/update the active connection from Dart
     */
    fun setXMPPConnection(connection: XMPPConnection) {
        xmppConnection = connection
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
