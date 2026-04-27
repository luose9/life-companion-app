package com.example.life_companion_app

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL_PRIVACY   = "life_companion/privacy"
    private val CHANNEL_WECHAT    = "life_companion/wechat_pay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── 屏幕安全标志 ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PRIVACY)
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecureFlag") {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }

        // ── 微信支付通知监听 ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WECHAT)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationAccessGranted" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "openNotificationAccess" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    }
                    "getPendingPayments" -> {
                        val prefs = getSharedPreferences(
                            WechatPayListenerService.PREFS_NAME, MODE_PRIVATE)
                        val json = prefs.getString(WechatPayListenerService.KEY_PAYMENTS, "[]") ?: "[]"
                        // 读取后立即清空，避免重复弹出
                        prefs.edit().putString(WechatPayListenerService.KEY_PAYMENTS, "[]").apply()
                        result.success(json)
                    }
                    "getPaymentHistory" -> {
                        val startMs = call.argument<Long>("startMs") ?: 0L
                        val endMs   = call.argument<Long>("endMs")   ?: Long.MAX_VALUE
                        val prefs   = getSharedPreferences(
                            WechatPayListenerService.HISTORY_NAME, MODE_PRIVATE)
                        val histJson = prefs.getString(WechatPayListenerService.KEY_HISTORY, "[]") ?: "[]"
                        val arr = try { org.json.JSONArray(histJson) } catch (e: Exception) { org.json.JSONArray() }
                        val filtered = org.json.JSONArray()
                        for (i in 0 until arr.length()) {
                            val item = arr.getJSONObject(i)
                            val ts = item.optLong("timestamp")
                            if (ts in startMs..endMs) filtered.put(item)
                        }
                        result.success(filtered.toString())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** 检查本应用是否已被授予通知监听权限 */
    private fun isNotificationListenerEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return flat.split(":").any { it.startsWith("$pkgName/") }
    }
}

