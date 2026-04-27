import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_companion_app/data/db_provider.dart';

class DataExportService {

  /// 所有需要备份的表
  static const _allTables = [
    'goals', 'tasks', 'moods', 'schedules', 'transactions',
    'workouts', 'entertainments', 'focus_sessions', 'checkin_records',
    'hobbies', 'hobby_works', 'body_records', 'persons',
    'relationship_moments', 'inspirations', 'gratitudes', 'milestones',
    'locations', 'tracks', 'track_points',
  ];

  /// 需要备份的 SharedPreferences 键
  static const _prefKeys = [
    'user_name', 'user_bio', 'user_avatar_path', 'app_theme',
    'user_created_at', 'bottom_nav_modules',
    'font_scale', 'notify_global', 'notify_modules',
    'use_24h', 'date_format', 'week_start',
    'vibration_enabled', 'sound_feedback_enabled',
    'minimal_mode', 'hide_numbers', 'no_reminder_mode',
    'fail_friendly_mode', 'vacation_mode',
    'app_lock_enabled', 'screenshot_enabled', 'first_launch_done',
  ];

  /// 导出所有表数据为 JSON，通过系统分享面板发送
  static Future<void> exportAllAsJson() async {
    final db = await DBProvider.db.database;
    final tables = [
      'goals', 'tasks', 'moods', 'schedules',
      'transactions', 'workouts', 'entertainments',
    ];

    final Map<String, dynamic> exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Life Companion',
    };

    for (final table in tables) {
      try {
        exportData[table] = await db.query(table, orderBy: 'id DESC');
      } catch (_) {
        exportData[table] = [];
      }
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename =
        'life_companion_${now.year}${_p(now.month)}${_p(now.day)}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonStr, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Life Companion 数据备份',
      text: '导出时间：${now.year}-${_p(now.month)}-${_p(now.day)}',
    );
  }

  // ══════════════════════════════════════════════════════════
  //  完整备份：所有表 + 用户设置
  // ══════════════════════════════════════════════════════════

  /// 导出全量备份（所有数据库表 + SharedPreferences 设置）
  static Future<void> exportFullBackup() async {
    final db = await DBProvider.db.database;
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> backup = {
      'backup_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Life Companion',
      'type': 'full_backup',
    };

    // 导出所有表
    for (final table in _allTables) {
      try {
        backup[table] = await db.query(table, orderBy: 'id ASC');
      } catch (_) {
        backup[table] = [];
      }
    }

    // 导出用户设置
    final settings = <String, dynamic>{};
    for (final key in _prefKeys) {
      final val = prefs.get(key);
      if (val != null) settings[key] = val;
    }
    backup['_settings'] = settings;

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename =
        'life_companion_full_${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonStr, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Life Companion 完整备份',
      text: '完整备份 · ${now.year}-${_p(now.month)}-${_p(now.day)} ${_p(now.hour)}:${_p(now.minute)}',
    );
  }

  // ══════════════════════════════════════════════════════════
  //  导入备份
  // ══════════════════════════════════════════════════════════

  /// 让用户选取 JSON 文件并导入，返回导入结果描述
  static Future<String> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return '已取消';
    }

    final fileBytes = result.files.first.bytes;
    final filePath = result.files.first.path;

    String jsonStr;
    if (fileBytes != null) {
      jsonStr = utf8.decode(fileBytes);
    } else if (filePath != null) {
      jsonStr = await File(filePath).readAsString(encoding: utf8);
    } else {
      return '无法读取文件';
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return '文件格式错误，不是有效的 JSON';
    }

    // 验证基本结构
    if (data['app'] != 'Life Companion') {
      return '不是 Life Companion 的备份文件';
    }

    final db = await DBProvider.db.database;
    int totalImported = 0;
    final errors = <String>[];

    // 确定要导入的表（兼容旧版只有 7 张表的导出）
    final tablesToImport = _allTables.where((t) => data.containsKey(t)).toList();

    for (final table in tablesToImport) {
      final rows = data[table];
      if (rows is! List) continue;

      try {
        // 使用事务批量插入
        await db.transaction((txn) async {
          for (final row in rows) {
            if (row is! Map) continue;
            final map = Map<String, dynamic>.from(row);
            // 移除 id 以避免主键冲突，让数据库自增
            map.remove('id');
            await txn.insert(table, map);
          }
        });
        totalImported += rows.length;
      } catch (e) {
        errors.add('$table: $e');
      }
    }

    // 恢复用户设置（仅恢复白名单内的键，防止注入）
    if (data.containsKey('_settings') && data['_settings'] is Map) {
      try {
        final settings = Map<String, dynamic>.from(data['_settings']);
        final prefs = await SharedPreferences.getInstance();
        for (final entry in settings.entries) {
          final key = entry.key;
          if (!_prefKeys.contains(key)) continue; // 跳过未知键
          final val = entry.value;
          if (val is String) {
            await prefs.setString(key, val);
          } else if (val is int) {
            await prefs.setInt(key, val);
          } else if (val is double) {
            await prefs.setDouble(key, val);
          } else if (val is bool) {
            await prefs.setBool(key, val);
          }
        }
      } catch (e) {
        errors.add('设置恢复: $e');
      }
    }

    final buf = StringBuffer('导入完成，共 $totalImported 条记录');
    if (errors.isNotEmpty) {
      buf.write('\n⚠️ ${errors.length} 个错误：\n${errors.join('\n')}');
    }
    return buf.toString();
  }

  /// 导入前清空所有数据（用于"覆盖导入"场景）
  static Future<void> clearAllTables() async {
    final db = await DBProvider.db.database;
    for (final t in _allTables) {
      try {
        await db.delete(t);
      } catch (_) {}
    }
  }

  /// 清除指定表所有数据
  static Future<void> clearTable(String table) async {
    final db = await DBProvider.db.database;
    await db.delete(table);
  }

  /// 清除全部用户数据
  static Future<void> clearAllData() async {
    final tables = [
      'goals', 'tasks', 'moods', 'schedules',
      'transactions', 'workouts', 'entertainments',
    ];
    for (final t in tables) {
      await clearTable(t);
    }
  }

  /// 统计各表记录数
  static Future<Map<String, int>> getTableCounts() async {
    final db = await DBProvider.db.database;
    final result = <String, int>{};
    for (final t in _allTables) {
      try {
        final rows = await db.rawQuery('SELECT COUNT(*) as c FROM $t');
        result[t] = (rows.first['c'] as int?) ?? 0;
      } catch (_) {
        result[t] = 0;
      }
    }
    return result;
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}
