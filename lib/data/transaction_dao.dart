import 'package:life_companion_app/data/db_provider.dart';
import 'package:life_companion_app/models/transaction.dart';

class TransactionDao {
  static Future<int> insert(TransactionEntry t) =>
      DBProvider.db.insert('transactions', t.toMap());

  static Future<List<TransactionEntry>> getAll() async {
    final db = await DBProvider.db.database;
    final maps = await db.query('transactions', orderBy: 'timestamp DESC');
    return maps.map(TransactionEntry.fromMap).toList();
  }

  static Future<List<TransactionEntry>> getByMonth(int year, int month) async {
    final db = await DBProvider.db.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;
    final maps = await db.query('transactions',
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [start, end],
        orderBy: 'timestamp DESC');
    return maps.map(TransactionEntry.fromMap).toList();
  }

  static Future<int> update(TransactionEntry t) =>
      DBProvider.db.update('transactions', t.toMap(), t.id!);

  static Future<int> delete(int id) =>
      DBProvider.db.delete('transactions', id);
}
