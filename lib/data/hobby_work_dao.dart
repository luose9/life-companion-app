import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/hobby_work.dart';

class HobbyWorkDao {
  static Future<int> insert(HobbyWork w) =>
      DBProvider.db.insert('hobby_works', w.toMap());

  static Future<List<HobbyWork>> getByHobbyId(int hobbyId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('hobby_works',
        where: 'hobby_id = ?', whereArgs: [hobbyId], orderBy: 'created_at DESC');
    return maps.map(HobbyWork.fromMap).toList();
  }

  static Future<List<HobbyWork>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('hobby_works', orderBy: 'created_at DESC');
    return maps.map(HobbyWork.fromMap).toList();
  }

  static Future<int> delete(int id) =>
      DBProvider.db.delete('hobby_works', id);
}
