import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/checkin_record.dart';

class CheckinDao {
  static Future<int> insert(CheckinRecord r) =>
      DBProvider.db.insert('checkin_records', r.toMap());

  static Future<List<CheckinRecord>> getByGoalId(int goalId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('checkin_records',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'timestamp DESC');
    return maps.map(CheckinRecord.fromMap).toList();
  }

  static Future<List<CheckinRecord>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('checkin_records', orderBy: 'timestamp DESC');
    return maps.map(CheckinRecord.fromMap).toList();
  }

  static Future<int> delete(int id) =>
      DBProvider.db.delete('checkin_records', id);

  static Future<int> countByGoalToday(int goalId) async {
    final db = await DBProvider.db.database;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + 86400000;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM checkin_records WHERE goal_id = ? AND timestamp >= ? AND timestamp < ?',
      [goalId, dayStart, dayEnd],
    );
    return (r.first['c'] as int?) ?? 0;
  }
}
