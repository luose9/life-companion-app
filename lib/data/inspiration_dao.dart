import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/inspiration.dart';

class InspirationDao {
  static Future<int> insert(Inspiration i) =>
      DBProvider.db.insert('inspirations', i.toMap());

  static Future<List<Inspiration>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('inspirations', orderBy: 'timestamp DESC');
    return maps.map(Inspiration.fromMap).toList();
  }

  static Future<List<Inspiration>> getByType(String type) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('inspirations',
        where: 'record_type = ?', whereArgs: [type], orderBy: 'timestamp DESC');
    return maps.map(Inspiration.fromMap).toList();
  }

  static Future<List<Inspiration>> search(String keyword) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('inspirations',
        where: 'content LIKE ? OR tags LIKE ? OR source LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
        orderBy: 'timestamp DESC');
    return maps.map(Inspiration.fromMap).toList();
  }

  static Future<int> update(Inspiration i) =>
      DBProvider.db.update('inspirations', i.toMap(), i.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('inspirations', id);
}
