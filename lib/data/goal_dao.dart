import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/goal.dart';

class GoalDao {
  static Future<int> insertGoal(Goal goal) async {
    return await DBProvider.db.insert('goals', goal.toMap());
  }

  static Future<List<Goal>> getAllGoals() async {
    final maps = await DBProvider.db.queryAll('goals');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<List<Goal>> getActiveGoals() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('goals',
        where: "status IN ('active', 'paused')", orderBy: 'created_at DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<List<Goal>> getByLevel(String level) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('goals',
        where: "level = ? AND status != 'archived'",
        whereArgs: [level],
        orderBy: 'created_at DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<List<Goal>> getChildren(int parentId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('goals',
        where: 'parent_id = ?', whereArgs: [parentId], orderBy: 'created_at DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<List<Goal>> getCompletedGoals() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('goals',
        where: "status = 'completed'", orderBy: 'end_date DESC');
    return maps.map((m) => Goal.fromMap(m)).toList();
  }

  static Future<int> countByLevel(String level) async {
    final db = await DBProvider.db.database;
    final r = await db.rawQuery(
      "SELECT COUNT(*) as c FROM goals WHERE level = ? AND status = 'active'",
      [level],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<int> updateGoal(Goal goal) async {
    if (goal.id == null) return 0;
    return await DBProvider.db.update('goals', goal.toMap(), goal.id!);
  }

  static Future<Goal?> getById(int id) async {
    final db = await DBProvider.db.database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  static Future<int> deleteGoal(int id) async {
    return await DBProvider.db.delete('goals', id);
  }
}
