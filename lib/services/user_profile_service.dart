import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const _kName = 'user_name';
  static const _kBio = 'user_bio';
  static const _kAvatarPath = 'user_avatar_path';
  static const _kTheme = 'app_theme'; // 'light' | 'dark' | 'system'
  static const _kCreatedAt = 'user_created_at';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── 读取 ──────────────────────────────────────────────────
  static Future<String> getName() async =>
      (await _prefs).getString(_kName) ?? '用户';

  static Future<String> getBio() async =>
      (await _prefs).getString(_kBio) ?? '';

  static Future<String?> getAvatarPath() async =>
      (await _prefs).getString(_kAvatarPath);

  static Future<String> getTheme() async =>
      (await _prefs).getString(_kTheme) ?? 'system';

  static Future<int> getCreatedAt() async {
    final prefs = await _prefs;
    if (!prefs.containsKey(_kCreatedAt)) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kCreatedAt, now);
      return now;
    }
    return prefs.getInt(_kCreatedAt) ?? DateTime.now().millisecondsSinceEpoch;
  }

  // ── 写入 ──────────────────────────────────────────────────
  static Future<void> setName(String v) async =>
      (await _prefs).setString(_kName, v.trim().isEmpty ? '用户' : v.trim());

  static Future<void> setBio(String v) async =>
      (await _prefs).setString(_kBio, v.trim());

  static Future<void> setAvatarPath(String? path) async {
    final prefs = await _prefs;
    if (path == null) {
      prefs.remove(_kAvatarPath);
    } else {
      prefs.setString(_kAvatarPath, path);
    }
  }

  static Future<void> setTheme(String v) async =>
      (await _prefs).setString(_kTheme, v);
}
