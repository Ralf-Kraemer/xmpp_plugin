package org.xrstudio.flutter_xmpp

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.jivesoftware.smack.XMPPConnection
import org.jivesoftware.smackx.carbons.CarbonManager

/** FlutterXmppPlugin */
class FlutterXmppPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var xmppConnection: XMPPConnection? = null

    companion object {
        private const val TAG = "FlutterXmppPlugin"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_xmpp")
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "enableMessageCarbons" -> {
                try {
                    enableMessageCarbons()
                    result.success(null)
                } catch (e: IllegalStateException) {
                    Log.e(TAG, "Failed to enable carbons: ${e.message}")
                    result.error("CARBONS_ERROR", e.message, null)
                } catch (e: Exception) {
                    Log.e(TAG, "Unexpected error enabling carbons", e)
                    result.error("CARBONS_ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Enable XMPP Message Carbons (XEP-0280) on the active connection
     * @throws IllegalStateException if connection is not set
     */
    private fun enableMessageCarbons() {
        val connection = xmppConnection ?: throw IllegalStateException("XMPP connection is not initialized")
        CarbonManager.getInstance(connection).apply {
            enableCarbons()
            Log.d(TAG, "XMPP Message Carbons enabled")
        }
    }

    /**
     * Set or update the active XMPP connection from Dart or another Kotlin class
     */
    fun setXMPPConnection(connection: XMPPConnection) {
        xmppConnection = connection
        Log.d(TAG, "XMPP connection set")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        xmppConnection = null
        Log.d(TAG, "FlutterXmppPlugin detached from engine")
    }
}
