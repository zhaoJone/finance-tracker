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
        private const val CACHE_CHANNEL = "com.financetracker/notification_cache"
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel: 实时通知流 ──
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // eventSink setter 内部做了 old sink 清理
                NotificationListener.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                NotificationListener.eventSink = null
            }
        })

        // ── MethodChannel: 缓存通知回放 ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CACHE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "flushCached" -> {
                    try {
                        val cached = NotificationListener.flushCached(this)
                        result.success(cached)
                    } catch (e: Exception) {
                        result.error("FLUSH_FAILED", "拉取缓存通知失败", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── MethodChannel: 打开通知使用权设置 ──
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
