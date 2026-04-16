import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/milestone.dart';

class MilestoneDao {
  static Future<int> insert(Milestone m) =>
      DBProvider.db.insert('milestones', m.toMap());

  static Future<List<Milestone>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('milestones', orderBy: 'event_date DESC');
    return maps.map(Milestone.fromMap).toList();
  }

  static Future<int> update(Milestone m) =>
      DBProvider.db.update('milestones', m.toMap(), m.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('milestones', id);
}
