import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/person.dart';

class PersonDao {
  static Future<int> insert(Person p) =>
      DBProvider.db.insert('persons', p.toMap());

  static Future<List<Person>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('persons', orderBy: 'created_at DESC');
    return maps.map(Person.fromMap).toList();
  }

  static Future<int> update(Person p) =>
      DBProvider.db.update('persons', p.toMap(), p.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('persons', id);
}

class RelationshipMomentDao {
  static Future<int> insert(RelationshipMoment m) =>
      DBProvider.db.insert('relationship_moments', m.toMap());

  static Future<List<RelationshipMoment>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('relationship_moments', orderBy: 'timestamp DESC');
    return maps.map(RelationshipMoment.fromMap).toList();
  }

  static Future<List<RelationshipMoment>> getByPerson(int personId) async {
    final db = await DBProvider.db.database;
    final maps = await db.query('relationship_moments',
        where: 'person_id = ?', whereArgs: [personId], orderBy: 'timestamp DESC');
    return maps.map(RelationshipMoment.fromMap).toList();
  }

  static Future<int> delete(int id) =>
      DBProvider.db.delete('relationship_moments', id);
}
