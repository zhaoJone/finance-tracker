package com.financetracker.finance_tracker_app

import android.app.Notification
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Android 通知监听服务 — 监听支付宝/微信/银行支付通知，
 * 通过 EventChannel 转发到 Flutter 层解析。
 *
 * 在系统设置中用户需手动授予「通知使用权」：
 *   设置 → 应用 → 特殊权限 → 通知使用权 → 启用 finance-tracker
 *
 * 目标应用包名：
 *   - 支付宝: com.eg.android.AlipayGphone
 *   - 微信: com.tencent.mm
 *   - 短信: com.google.android.apps.messaging / com.android.mms / 等
 */
class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "com.financetracker/notifications"

        // 目标应用的包名
        private val TARGET_PACKAGES = setOf(
            "com.eg.android.AlipayGphone",   // 支付宝
            "com.tencent.mm",                 // 微信
            "com.google.android.apps.messaging", // Google 短信
            "com.android.mms",                // 原生短信
            "com.android.systemui",           // MIUI/ColorOS 短信可能经过 systemui
            "com.samsung.android.messaging",  // 三星短信
        )

        // 通知文本中的关键词，用于过滤出支付类通知
        private val PAYMENT_KEYWORDS = setOf(
            "支付宝", "微信支付", "支出", "收入", "消费",
            "转账", "收到", "到账", "付款"
        )

        // EventChannel sink — 由 Flutter 端初始化时设置
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onListenerConnected() {
        Log.d(TAG, "通知监听服务已连接")
    }

    override fun onListenerDisconnected() {
        Log.d(TAG, "通知监听服务已断开")
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName

        // 只处理目标应用的通知
        if (packageName !in TARGET_PACKAGES) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        // 提取标题和文本
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
        val bigText = run {
            val big = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            big?.toString() ?: ""
        }

        var fullContent = buildString {
            if (title.isNotBlank()) append(title)
            if (text.isNotBlank()) {
                if (isNotEmpty()) append(" ")
                append(text)
            }
            if (bigText.isNotBlank()) {
                if (isNotEmpty()) append(" ")
                append(bigText)
            }
        }

        // 如果标题或文本中没有支付相关关键词，跳过
        if (!PAYMENT_KEYWORDS.any { fullContent.contains(it) }) return

        Log.d(TAG, "捕获支付通知 [$packageName]: $fullContent")

        // 通过 EventChannel 发送到 Flutter
        val sink = eventSink
        if (sink != null) {
            try {
                sink.success(mapOf(
                    "source" to when (packageName) {
                        "com.eg.android.AlipayGphone" -> "alipay"
                        "com.tencent.mm" -> "wechat"
                        else -> "bank"
                    },
                    "rawText" to fullContent,
                    "packageName" to packageName,
                ))
            } catch (e: Exception) {
                Log.e(TAG, "发送通知到 Flutter 失败", e)
            }
        } else {
            Log.w(TAG, "EventChannel sink 未初始化，通知将被忽略")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // 不需要处理移除事件
    }
}
