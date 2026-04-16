import 'dart:math';
import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/gratitude.dart';

class GratitudeDao {
  static Future<int> insert(Gratitude g) =>
      DBProvider.db.insert('gratitudes', g.toMap());

  static Future<List<Gratitude>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('gratitudes', orderBy: 'timestamp DESC');
    return maps.map(Gratitude.fromMap).toList();
  }

  static Future<List<Gratitude>> getToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
    final db = await DBProvider.db.database;
    final maps = await db.query('gratitudes',
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [start, end],
        orderBy: 'timestamp DESC');
    return maps.map(Gratitude.fromMap).toList();
  }

  static Future<Gratitude?> getRandom() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('gratitudes');
    if (maps.isEmpty) return null;
    return Gratitude.fromMap(maps[Random().nextInt(maps.length)]);
  }

  static Future<int> delete(int id) =>
      DBProvider.db.delete('gratitudes', id);
}
