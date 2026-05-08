package com.financetracker.finance_tracker_app

import android.app.Notification
import android.content.Context
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Android 通知监听服务 — 监听支付宝/微信/银行支付通知，
 * 通过 EventChannel 转发到 Flutter 层解析。
 *
 * 双重保障：无论 EventChannel 是否连通，先写入本地缓存。
 * Flutter 恢复时通过 MethodChannel 拉取缓存历史，回放后再清空。
 *
 * 在系统设置中用户需手动授予「通知使用权」：
 *   设置 → 应用 → 特殊权限 → 通知使用权 → 启用 finance-tracker
 *
 * 目标应用包名：
 *   - 支付宝: com.eg.android.AlipayGphone
 *   - 微信: com.tencent.mm
 */
class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "com.financetracker/notifications"
        private const val CACHE_PREFS = "notif_cache"
        private const val MAX_CACHED = 500

        // 目标应用的包名
        private val TARGET_PACKAGES = setOf(
            "com.eg.android.AlipayGphone",   // 支付宝
            "com.tencent.mm",                 // 微信
        )

        // 通知文本中的关键词，用于过滤出支付类通知
        private val PAYMENT_KEYWORDS = setOf(
            "支付宝", "微信支付", "支出", "收入", "消费",
            "转账", "收到", "到账", "付款"
        )

        // EventChannel sink — 由 Flutter 端初始化时设置
        var eventSink: EventChannel.EventSink? = null
            set(value) {
                // 清除旧 sink（避免 Activity 重建后引用已失效的通道）
                field?.let { old ->
                    try { old.endOfStream() } catch (_: Exception) {}
                }
                field = value
            }

        // 后台 IO 线程，负责缓存写入/淘汰，不阻塞主线程
        private val IO_EXECUTOR = Executors.newSingleThreadExecutor { r ->
            Thread(r, "notif-cache-io").apply { isDaemon = true }
        }

        // ─── 缓存核心方法 ─────────────────────────────

        /** 生成通知指纹（MD5 包名+文本，用于去重） */
        fun notificationFingerprint(pkg: String, text: String): String {
            val normalized = text.replace(Regex("\\s+"), "").take(200)
            val digest = MessageDigest.getInstance("MD5")
            return digest.digest(("$pkg|$normalized").toByteArray())
                .joinToString("") { "%02x".format(it) }
        }

        /** 检查指纹是否已缓存 */
        @Synchronized
        fun isNotificationCached(context: Context, fingerprint: String): Boolean {
            return context.getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
                .contains("notif_$fingerprint")
        }

        /** 写入单条通知缓存（独立 key，无竞态冲突） */
        @Synchronized
        fun saveNotification(
            context: Context,
            fingerprint: String,
            source: String,
            rawText: String,
            packageName: String
        ) {
            val prefs = context.getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
            val key = "notif_$fingerprint"

            // 双重去重检查
            if (prefs.contains(key)) return

            // 淘汰旧条目，防止无限膨胀
            pruneIfNeeded(prefs)

            prefs.edit().putString(key, JSONObject().apply {
                put("fingerprint", fingerprint)
                put("source", source)
                put("rawText", rawText)
                put("packageName", packageName)
                put("timestampMs", System.currentTimeMillis())
            }.toString()).commit() // commit = 同步写入，确保不丢
        }

        /** 淘汰最旧的条目，保留最新 MAX_CACHED 条 */
        private fun pruneIfNeeded(prefs: android.content.SharedPreferences) {
            val all = prefs.all.filterKeys { it.startsWith("notif_") }
            if (all.size < MAX_CACHED) return

            val sorted = all.entries
                .mapNotNull { (key, value) ->
                    try {
                        key to JSONObject(value as String).getLong("timestampMs")
                    } catch (_: Exception) { null }
                }
                .sortedBy { (_, ts) -> ts }

            val toRemove = sorted.take(100).map { it.first }
            prefs.edit().apply {
                toRemove.forEach { remove(it) }
                apply()
            }
        }

        /** 清除 7 天前的过期缓存 */
        private fun pruneExpired(prefs: android.content.SharedPreferences) {
            val cutoff = System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000L
            val toRemove = prefs.all.filterKeys { it.startsWith("notif_") }
                .mapNotNull { (key, value) ->
                    try {
                        val ts = JSONObject(value as String).getLong("timestampMs")
                        if (ts < cutoff) key else null
                    } catch (_: Exception) { key }
                }
            if (toRemove.isNotEmpty()) {
                prefs.edit().apply {
                    toRemove.forEach { remove(it) }
                    commit() // 同步清除
                }
            }
        }

        /**
         * 取出所有缓存并清除（一次性消费）。
         * 供 MainActivity 的 MethodChannel 调用。
         */
        @Synchronized
        fun flushCached(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
            val result = mutableListOf<Map<String, Any>>()
            val editor = prefs.edit()

            prefs.all.filterKeys { it.startsWith("notif_") }.forEach { (key, value) ->
                try {
                    val json = JSONObject(value as String)
                    result.add(mapOf(
                        "fingerprint" to json.getString("fingerprint"),
                        "source" to json.getString("source"),
                        "rawText" to json.getString("rawText"),
                        "packageName" to json.getString("packageName"),
                        "timestampMs" to json.getLong("timestampMs")
                    ))
                } catch (_: Exception) {}
                editor.remove(key)
            }
            editor.commit() // 同步清除，确保不重复返回
            return result
        }
    }

    override fun onListenerConnected() {
        Log.d(TAG, "通知监听服务已连接")
        // 后台清理过期缓存
        IO_EXECUTOR.execute {
            val prefs = getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
            pruneExpired(prefs)
        }
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

        val fullContent = buildString {
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

        val source = when (packageName) {
            "com.eg.android.AlipayGphone" -> "alipay"
            "com.tencent.mm" -> "wechat"
            else -> "bank"
        }
        val fingerprint = notificationFingerprint(packageName, fullContent)

        // Step 1: 先写缓存（无条件下都写）
        // 在 IO 线程写入，避免阻塞主线程
        if (!isNotificationCached(this, fingerprint)) {
            IO_EXECUTOR.execute {
                saveNotification(this, fingerprint, source, fullContent, packageName)
            }
        }

        // Step 2: 再通过 EventChannel 实时推送（sink 可用时）
        val sink = eventSink
        if (sink != null) {
            try {
                sink.success(mapOf(
                    "fingerprint" to fingerprint,
                    "source" to source,
                    "rawText" to fullContent,
                    "packageName" to packageName,
                ))
            } catch (e: Exception) {
                Log.e(TAG, "发送通知到 Flutter 失败", e)
            }
        } else {
            Log.d(TAG, "EventChannel sink 未初始化，通知已缓存等待回放")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // 不需要处理移除事件
    }
}
