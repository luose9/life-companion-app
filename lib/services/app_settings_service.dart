import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局设置管理 — 所有偏好设置集中在此
class AppSettingsService {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ═══ 键名 ═══
  // 字体
  static const _kFontScale = 'font_scale'; // 0.85 / 1.0 / 1.15 / 1.3
  // 通知
  static const _kNotifyGlobal = 'notify_global';
  static const _kNotifyModules = 'notify_modules'; // JSON map
  // 时间格式
  static const _kUse24h = 'use_24h';
  static const _kDateFormat = 'date_format'; // 'ymd' | 'mdy'
  static const _kWeekStart = 'week_start'; // 'mon' | 'sun'
  // 反馈
  static const _kVibration = 'vibration_enabled';
  static const _kSoundFeedback = 'sound_feedback_enabled';
  // 反焦虑
  static const _kMinimalMode = 'minimal_mode';
  static const _kHideNumbers = 'hide_numbers';
  static const _kNoReminder = 'no_reminder_mode';
  static const _kFailFriendly = 'fail_friendly_mode';
  // 休假模式
  static const _kVacationMode = 'vacation_mode';

  // ═══ 字体大小 ═══
  static Future<double> getFontScale() async =>
      (await _prefs).getDouble(_kFontScale) ?? 1.0;

  static Future<void> setFontScale(double v) async =>
      (await _prefs).setDouble(_kFontScale, v);

  // ═══ 通知 ═══
  static Future<bool> isNotifyGlobal() async =>
      (await _prefs).getBool(_kNotifyGlobal) ?? true;

  static Future<void> setNotifyGlobal(bool v) async =>
      (await _prefs).setBool(_kNotifyGlobal, v);

  static Future<Map<String, bool>> getNotifyModules() async {
    final json = (await _prefs).getString(_kNotifyModules);
    if (json == null) return {};
    try {
      return Map<String, bool>.from(jsonDecode(json));
    } catch (_) {
      return {};
    }
  }

  static Future<void> setNotifyModules(Map<String, bool> m) async =>
      (await _prefs).setString(_kNotifyModules, jsonEncode(m));

  static Future<bool> isModuleNotifyEnabled(String module) async {
    if (!await isNotifyGlobal()) return false;
    final modules = await getNotifyModules();
    return modules[module] ?? true;
  }

  // ═══ 时间/日期格式 ═══
  static Future<bool> use24h() async =>
      (await _prefs).getBool(_kUse24h) ?? true;

  static Future<void> setUse24h(bool v) async =>
      (await _prefs).setBool(_kUse24h, v);

  static Future<String> getDateFormat() async =>
      (await _prefs).getString(_kDateFormat) ?? 'ymd';

  static Future<void> setDateFormat(String v) async =>
      (await _prefs).setString(_kDateFormat, v);

  static Future<String> getWeekStart() async =>
      (await _prefs).getString(_kWeekStart) ?? 'mon';

  static Future<void> setWeekStart(String v) async =>
      (await _prefs).setString(_kWeekStart, v);

  // ═══ 反馈 ═══
  static Future<bool> isVibrationEnabled() async =>
      (await _prefs).getBool(_kVibration) ?? true;

  static Future<void> setVibration(bool v) async =>
      (await _prefs).setBool(_kVibration, v);

  static Future<bool> isSoundFeedbackEnabled() async =>
      (await _prefs).getBool(_kSoundFeedback) ?? true;

  static Future<void> setSoundFeedback(bool v) async =>
      (await _prefs).setBool(_kSoundFeedback, v);

  // ═══ 反焦虑模式 ═══
  static Future<bool> isMinimalMode() async =>
      (await _prefs).getBool(_kMinimalMode) ?? false;

  static Future<void> setMinimalMode(bool v) async =>
      (await _prefs).setBool(_kMinimalMode, v);

  static Future<bool> isHideNumbers() async =>
      (await _prefs).getBool(_kHideNumbers) ?? false;

  static Future<void> setHideNumbers(bool v) async =>
      (await _prefs).setBool(_kHideNumbers, v);

  static Future<bool> isNoReminderMode() async =>
      (await _prefs).getBool(_kNoReminder) ?? false;

  static Future<void> setNoReminderMode(bool v) async =>
      (await _prefs).setBool(_kNoReminder, v);

  static Future<bool> isFailFriendlyMode() async =>
      (await _prefs).getBool(_kFailFriendly) ?? false;

  static Future<void> setFailFriendlyMode(bool v) async =>
      (await _prefs).setBool(_kFailFriendly, v);

  // ═══ 休假模式 ═══
  static Future<bool> isVacationMode() async =>
      (await _prefs).getBool(_kVacationMode) ?? false;

  static Future<void> setVacationMode(bool v) async =>
      (await _prefs).setBool(_kVacationMode, v);

  // ═══ 一键无压力模式 ═══
  static Future<void> applyZeroPressure() async {
    await setMinimalMode(true);
    await setHideNumbers(true);
    await setNoReminderMode(true);
    await setFailFriendlyMode(true);
    await setVibration(false);
    await setSoundFeedback(false);
  }

  static Future<void> resetZeroPressure() async {
    await setMinimalMode(false);
    await setHideNumbers(false);
    await setNoReminderMode(false);
    await setFailFriendlyMode(false);
    await setVibration(true);
    await setSoundFeedback(true);
  }
}
