import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/workout.dart';

class WorkoutDao {
  static Future<int> insert(Workout w) =>
      DBProvider.db.insert('workouts', w.toMap());

  static Future<List<Workout>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('workouts', orderBy: 'start_time DESC');
    return maps.map(Workout.fromMap).toList();
  }

  static Future<int> update(Workout w) =>
      DBProvider.db.update('workouts', w.toMap(), w.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('workouts', id);
}
