import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/focus_session.dart';

class FocusSessionDao {
  static Future<int> insert(FocusSession s) =>
      DBProvider.db.insert('focus_sessions', s.toMap());

  static Future<List<FocusSession>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('focus_sessions', orderBy: 'start_time DESC');
    return maps.map(FocusSession.fromMap).toList();
  }

  static Future<List<FocusSession>> getByGoalId(int goalId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('focus_sessions',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'start_time DESC');
    return maps.map(FocusSession.fromMap).toList();
  }

  static Future<int> delete(int id) =>
      DBProvider.db.delete('focus_sessions', id);
}
