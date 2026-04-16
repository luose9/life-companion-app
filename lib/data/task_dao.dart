import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/task.dart';

class TaskDao {
  static Future<int> insertTask(TaskItem task) async {
    return await DBProvider.db.insert('tasks', task.toMap());
  }

  static Future<List<TaskItem>> getTasksByGoal(int goalId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('tasks', where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'id ASC');
    return maps.map((m) => TaskItem.fromMap(m)).toList();
  }

  static Future<int> toggleDone(TaskItem task) async {
    final newDone = task.done == 1 ? 0 : 1;
    task.done = newDone;
    return await DBProvider.db.update('tasks', task.toMap(), task.id!);
  }

  static Future<int> deleteTask(int id) async {
    return await DBProvider.db.delete('tasks', id);
  }
}
