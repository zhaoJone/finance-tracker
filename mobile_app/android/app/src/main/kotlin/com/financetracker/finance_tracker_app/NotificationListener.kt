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
 * Android 通知监听服务 — 通过文本关键词过滤支付通知，
 * 通过 EventChannel 转发到 Flutter 层解析。
 *
 * 简化模式（无前台保活 -> 2026-05-09 回退）：
 * - onNotificationPosted 收到通知 → 关键词预检 → 缓存 + EventChannel 推送
 * - 所有重操作在 IO 线程执行，不阻塞主线程
 * - 不依赖 foreground service，消除国产 ROM 上 startForeground 闪退的根源
 * - App 被杀后，通过缓存回放机制（flushCached）恢复通知
 *
 * 缓存 + EventChannel 双重保障：
 *   1. 先写 SharedPreferences 缓存（无论 EventChannel 是否连通）
 *   2. 再通过 EventChannel 实时推送到 Flutter
 *   3. Flutter 启动/恢复时通过 MethodChannel 拉取缓存回放
 */
class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "com.financetracker/notifications"
        private const val CACHE_PREFS = "notif_cache"
        private const val MAX_CACHED = 500

        // 关键词 — 用于过滤出支付类通知（在拼接的完整内容中搜索）
        private val PAYMENT_KEYWORDS = setOf(
            "支付宝", "微信支付", "招商银行", "支出", "收入", "消费",
            "转账", "收到", "到账", "付款", "还款", "扣款", "退款"
        )

        // 缓存 Regex + MessageDigest（避免每次 new 实例）
        private val WHITESPACE = Regex("\\s+")
        // MD5 非线程安全，访问需同步
        private val MD5 = MessageDigest.getInstance("MD5")

        // EventChannel sink — 由 Flutter 端初始化时设置
        // @Volatile 确保 IO 线程能读到主线程写入的最新值
        @Volatile
        var eventSink: EventChannel.EventSink? = null
            set(value) {
                field?.let { old ->
                    try { old.endOfStream() } catch (_: Exception) {}
                }
                field = value
            }

        // 后台 IO 线程池（单线程，避免竞态）
        private val IO_EXECUTOR = Executors.newSingleThreadExecutor { r ->
            Thread(r, "notif-cache-io").apply { isDaemon = true }
        }

        // ─── 指纹 + 缓存 ─────────────────────────────

        /** 生成通知指纹（MD5 包名+文本，用于去重） */
        fun notificationFingerprint(pkg: String, text: String): String {
            val normalized = text.replace(WHITESPACE, "").take(200)
            synchronized(MD5) {
                MD5.reset()
                return MD5.digest(("$pkg|$normalized").toByteArray())
                    .joinToString("") { "%02x".format(it) }
            }
        }

        /** 检查指纹是否已缓存 */
        @Synchronized
        fun isNotificationCached(context: Context, fingerprint: String): Boolean {
            return context.getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
                .contains("notif_$fingerprint")
        }

        /** 写入单条通知缓存 */
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
            if (prefs.contains(key)) return
            pruneIfNeeded(prefs)
            prefs.edit().putString(key, JSONObject().apply {
                put("fingerprint", fingerprint)
                put("source", source)
                put("rawText", rawText)
                put("packageName", packageName)
                put("timestampMs", System.currentTimeMillis())
            }.toString()).commit()
        }

        private fun pruneIfNeeded(prefs: android.content.SharedPreferences) {
            val all = prefs.all.filterKeys { it.startsWith("notif_") }
            if (all.size < MAX_CACHED) return
            val sorted = all.entries
                .mapNotNull { (key, value) ->
                    try { key to JSONObject(value as String).getLong("timestampMs") }
                    catch (_: Exception) { null }
                }
                .sortedBy { (_, ts) -> ts }
            val toRemove = sorted.take(100).map { it.first }
            prefs.edit().apply {
                toRemove.forEach { remove(it) }
                apply()
            }
        }

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
                    commit()
                }
            }
        }

        /** 取出所有缓存并清除（一次性消费） */
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
            editor.commit()
            return result
        }
    }

    // ─── 生命周期 ─────────────────────────────

    override fun onListenerConnected() {
        Log.d(TAG, "通知监听服务已连接")
        // 后台清理过期缓存
        IO_EXECUTOR.execute {
            val prefs = getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
            pruneExpired(prefs)
        }
    }

    override fun onListenerDisconnected() {
        Log.w(TAG, "通知监听服务已断开")
        // 请求系统重新绑定（国产 ROM 上可能不生效，但无副作用）
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                requestRebind(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "请求重连失败", e)
        }
    }

    // ─── 通知处理 ─────────────────────────────

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        // 提取标题、文本、大文本
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
        val bigText = run {
            val big = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            big?.toString() ?: ""
        }

        // 拼接完整内容（用于关键词检测 + 推送）
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

        // 关键词预检（在 fullContent 上搜索，不遗漏 EXTRA_BIG_TEXT 中的关键词）
        if (!PAYMENT_KEYWORDS.any { fullContent.contains(it) }) return

        Log.d(TAG, "捕获支付通知 [$packageName]: $title $text")

        val source = when (packageName) {
            "com.eg.android.AlipayGphone" -> "alipay"
            "com.tencent.mm" -> "wechat"
            else -> "bank"
        }
        val fingerprint = notificationFingerprint(packageName, fullContent)

        // 写缓存（IO 线程，不阻塞主线程）
        IO_EXECUTOR.execute {
            if (!isNotificationCached(this@NotificationListener, fingerprint)) {
                saveNotification(this@NotificationListener, fingerprint, source, fullContent, packageName)
            }
        }

        // 实时推送 EventChannel（主线程，无竞态 — 与 Flutter onCancel 同线程）
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
