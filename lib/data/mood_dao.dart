import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/mood.dart';

class MoodDao {
  static Future<int> insertMood(Mood mood) async {
    return await DBProvider.db.insert('moods', mood.toMap());
  }

  static Future<List<Mood>> getAllMoods() async {
    final maps = await DBProvider.db.queryAll('moods');
    return maps.map((m) => Mood.fromMap(m)).toList();
  }

  static Future<int> deleteMood(int id) async {
    return await DBProvider.db.delete('moods', id);
  }

  static Future<List<Mood>> getByDateRange(int startMs, int endMs) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('moods',
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [startMs, endMs],
        orderBy: 'timestamp DESC');
    return maps.map((m) => Mood.fromMap(m)).toList();
  }

  static Future<List<Mood>> getRecent(int days) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final db = await DBProvider.db.database;
    final maps = await db.query('moods',
        where: 'timestamp >= ?',
        whereArgs: [since],
        orderBy: 'timestamp DESC');
    return maps.map((m) => Mood.fromMap(m)).toList();
  }
}
