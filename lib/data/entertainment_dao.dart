import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/entertainment.dart';

class EntertainmentDao {
  static Future<int> insert(Entertainment e) =>
      DBProvider.db.insert('entertainments', e.toMap());

  static Future<List<Entertainment>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('entertainments', orderBy: 'timestamp DESC');
    return maps.map(Entertainment.fromMap).toList();
  }

  static Future<int> update(Entertainment e) =>
      DBProvider.db.update('entertainments', e.toMap(), e.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('entertainments', id);
}
