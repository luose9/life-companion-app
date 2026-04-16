import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:life_companion_app/data/db_provider.dart';

class DataExportService {
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
    final tables = [
      'goals', 'tasks', 'moods', 'schedules',
      'transactions', 'workouts', 'entertainments',
    ];
    final result = <String, int>{};
    for (final t in tables) {
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
