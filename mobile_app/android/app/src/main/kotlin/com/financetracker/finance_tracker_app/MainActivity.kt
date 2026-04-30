package com.financetracker.finance_tracker_app

import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val NOTIFICATION_CHANNEL = "com.financetracker/notifications"
        private const val SETTINGS_CHANNEL = "com.financetracker/settings"
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 注册通知监听 EventChannel
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NotificationListener.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                NotificationListener.eventSink = null
            }
        })

        // 注册设置页 MethodChannel（打开通知使用权设置）
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SETTINGS_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "openNotificationListenerSettings") {
                try {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    } else {
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    }
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("OPEN_FAILED", "Failed to open settings", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
