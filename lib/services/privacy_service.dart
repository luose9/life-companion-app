import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 锁定状态 + 运行时权限工具
class PrivacyService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _kAppLockEnabled = 'app_lock_enabled';
  static const _kScreenshotEnabled = 'screenshot_enabled'; // false = 禁止截图
  static const _kFirstLaunch = 'first_launch_done';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ────────────────────────────────────────────────────────
  // 首次启动检测
  // ────────────────────────────────────────────────────────
  static Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    final done = prefs.getBool(_kFirstLaunch) ?? false;
    return !done;
  }

  static Future<void> markLaunchDone() async =>
      (await _prefs).setBool(_kFirstLaunch, true);

  // ────────────────────────────────────────────────────────
  // App 锁
  // ────────────────────────────────────────────────────────
  static Future<bool> isAppLockEnabled() async =>
      (await _prefs).getBool(_kAppLockEnabled) ?? false;

  static Future<void> setAppLockEnabled(bool v) async =>
      (await _prefs).setBool(_kAppLockEnabled, v);

  /// true = 设备支持生物识别 / PIN
  static Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// 请求生物识别验证，成功返回 true
  static Future<bool> authenticate({
    String reason = '请验证身份以访问 Life Companion',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // 允许回退 PIN
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // ────────────────────────────────────────────────────────
  // 截图保护（通过 FLAG_SECURE）
  // ────────────────────────────────────────────────────────
  static final _channel = const MethodChannel('life_companion/privacy');

  static Future<bool> isScreenshotProtected() async =>
      !((await _prefs).getBool(_kScreenshotEnabled) ?? true);

  static Future<void> setScreenshotProtection(bool protect) async {
    await (await _prefs).setBool(_kScreenshotEnabled, !protect);
    try {
      await _channel.invokeMethod('setSecureFlag', {'secure': protect});
    } on PlatformException {
      // 忽略不支持的平台
    }
  }
}
