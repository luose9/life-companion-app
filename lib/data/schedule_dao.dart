import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/schedule.dart';

class ScheduleDao {
  static Future<int> insertSchedule(Schedule s) async {
    return await DBProvider.db.insert('schedules', s.toMap());
  }

  static Future<List<Schedule>> getAllSchedules() async {
    final maps = await DBProvider.db.queryAll('schedules');
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  static Future<int> updateSchedule(Schedule s) async {
    if (s.id == null) return 0;
    return await DBProvider.db.update('schedules', s.toMap(), s.id!);
  }

  static Future<int> deleteSchedule(int id) async {
    return await DBProvider.db.delete('schedules', id);
  }

  static Future<List<Schedule>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;
    final db = await DBProvider.db.database;
    final maps = await db.query('schedules',
        where: 'start_time >= ? AND start_time < ?',
        whereArgs: [start, end],
        orderBy: 'start_time ASC');
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  static Future<int> countTodayByPriority(String priority) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
    final db = await DBProvider.db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM schedules WHERE start_time >= ? AND start_time < ? AND priority = ? AND status != 'done'",
      [start, end, priority],
    );
    return result.first['cnt'] as int? ?? 0;
  }

  /// Postpone: move to tomorrow
  static Future<void> postponeToTomorrow(Schedule s) async {
    if (s.startTime != null) {
      s.startTime = s.startTime! + 86400000;
    }
    if (s.endTime != null) {
      s.endTime = s.endTime! + 86400000;
    }
    s.status = 'postponed';
    await updateSchedule(s);
  }
}
