import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/body_record.dart';

class BodyRecordDao {
  static Future<int> insert(BodyRecord r) =>
      DBProvider.db.insert('body_records', r.toMap());

  static Future<List<BodyRecord>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('body_records', orderBy: 'timestamp DESC');
    return maps.map(BodyRecord.fromMap).toList();
  }

  static Future<List<BodyRecord>> getByType(String type) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('body_records',
        where: 'record_type = ?', whereArgs: [type], orderBy: 'timestamp DESC');
    return maps.map(BodyRecord.fromMap).toList();
  }

  static Future<int> update(BodyRecord r) =>
      DBProvider.db.update('body_records', r.toMap(), r.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('body_records', id);
}
