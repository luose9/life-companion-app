import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/hobby.dart';

class HobbyDao {
  static Future<int> insert(Hobby h) =>
      DBProvider.db.insert('hobbies', h.toMap());

  static Future<List<Hobby>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('hobbies', orderBy: 'created_at DESC');
    return maps.map(Hobby.fromMap).toList();
  }

  static Future<int> update(Hobby h) =>
      DBProvider.db.update('hobbies', h.toMap(), h.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('hobbies', id);

  static Future<Hobby?> getById(int id) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('hobbies', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Hobby.fromMap(maps.first);
  }

  /// 按名称查找（忽略大小写），用于去重判断
  static Future<Hobby?> getByName(String name) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('hobbies',
        where: 'LOWER(name) = LOWER(?)', whereArgs: [name.trim()]);
    if (maps.isEmpty) return null;
    return Hobby.fromMap(maps.first);
  }
}
