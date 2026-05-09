package com.financetracker.finance_tracker_app

import android.app.Notification
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Android 通知监听服务 — 通过文本关键词过滤支付通知，
 * 通过 EventChannel 转发到 Flutter 层解析。
 *
 * 简化模式（无前台保活）：
 * - onNotificationPosted 收到通知 → 关键词预检 → 缓存 + EventChannel 推送
 * - 缓存使用 EncryptedSharedPreferences 加密存储，保护金融数据
 * - App 被杀后，通过缓存回放机制（flushCached）恢复通知
 */
class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "com.financetracker/notifications"
        private const val CACHE_PREFS = "notif_cache"
        private const val MAX_CACHED = 500

        // 关键词
        private val PAYMENT_KEYWORDS = setOf(
            "支付宝", "微信支付", "招商银行", "支出", "收入", "消费",
            "转账", "收到", "到账", "付款", "还款", "扣款", "退款"
        )

        private val WHITESPACE = Regex("\\s+")
        // P2: SHA-256 替代 MD5 — 指纹碰撞抗性更强
        private val SHA256 = MessageDigest.getInstance("SHA-256")

        @Volatile
        var eventSink: EventChannel.EventSink? = null
            set(value) {
                field?.let { old ->
                    try { old.endOfStream() } catch (_: Exception) {}
                }
                field = value
            }

        private val IO_EXECUTOR = Executors.newSingleThreadExecutor { r ->
            Thread(r, "notif-cache-io").apply { isDaemon = true }
        }

        // ─── 加密缓存 ─────────────────────────────

        /**
         * 获取加密的 SharedPreferences 实例。
         * P0: 使用 EncryptedSharedPreferences 加密存储通知内容，
         * 防止 root 设备或恶意 App 读取明文金融数据。
         */
        private fun getSecurePrefs(context: Context): SharedPreferences {
            return try {
                val masterKey = MasterKey.Builder(context)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build()
                EncryptedSharedPreferences.create(
                    context,
                    CACHE_PREFS,
                    masterKey,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                )
            } catch (e: Exception) {
                Log.w(TAG, "加密 SP 创建失败，降级到普通 SP", e)
                context.getSharedPreferences(CACHE_PREFS, Context.MODE_PRIVATE)
            }
        }

        /** 生成通知指纹（SHA-256 包名+文本，用于去重） */
        fun notificationFingerprint(pkg: String, text: String): String {
            val normalized = text.replace(WHITESPACE, "").take(200)
            synchronized(SHA256) {
                SHA256.reset()
                return SHA256.digest(("$pkg|$normalized").toByteArray())
                    .joinToString("") { "%02x".format(it) }
            }
        }

        @Synchronized
        fun isNotificationCached(context: Context, fingerprint: String): Boolean {
            return getSecurePrefs(context).contains("notif_$fingerprint")
        }

        @Synchronized
        fun saveNotification(
            context: Context,
            fingerprint: String,
            source: String,
            rawText: String,
            packageName: String
        ) {
            val prefs = getSecurePrefs(context)
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

        private fun pruneIfNeeded(prefs: SharedPreferences) {
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

        private fun pruneExpired(prefs: SharedPreferences) {
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

        @Synchronized
        fun flushCached(context: Context): List<Map<String, Any>> {
            val prefs = getSecurePrefs(context)
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
        IO_EXECUTOR.execute {
            val prefs = getSecurePrefs(this@NotificationListener)
            pruneExpired(prefs)
        }
    }

    override fun onListenerDisconnected() {
        Log.w(TAG, "通知监听服务已断开")
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                requestRebind(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "请求重连失败", e)
        }
    }

    /**
     * P1: Service 销毁时关闭 IO 线程池，
     * 防止 IO 队列中的任务持有已销毁 Service 的 Context 引用导致崩溃。
     */
    override fun onDestroy() {
        super.onDestroy()
        IO_EXECUTOR.shutdownNow()
        Log.d(TAG, "IO 线程池已关闭")
    }

    // ─── 通知处理 ─────────────────────────────

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

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

        if (!PAYMENT_KEYWORDS.any { fullContent.contains(it) }) return

        // P0: Log.d 脱敏 — 只输出前 16 字符，不暴露完整交易信息
        Log.d(TAG, "捕获支付通知 [$packageName]: ${title.take(16)}... ${text.take(16)}...")

        val source = when (packageName) {
            "com.eg.android.AlipayGphone" -> "alipay"
            "com.tencent.mm" -> "wechat"
            else -> "bank"
        }
        val fingerprint = notificationFingerprint(packageName, fullContent)

        IO_EXECUTOR.execute {
            if (!isNotificationCached(this@NotificationListener, fingerprint)) {
                saveNotification(this@NotificationListener, fingerprint, source, fullContent, packageName)
            }
        }

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
