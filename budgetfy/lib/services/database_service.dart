import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = join(await getDatabasesPath(), 'budgetfy.db');
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          is_income INTEGER NOT NULL,
          date TEXT NOT NULL,
          category TEXT NOT NULL,
          is_recurring INTEGER NOT NULL DEFAULT 0,
          recurring_type TEXT NOT NULL DEFAULT 'monthly',
          recurring_interval INTEGER NOT NULL DEFAULT 7
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN recurring_type TEXT NOT NULL DEFAULT 'monthly'",
          );
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurring_interval INTEGER NOT NULL DEFAULT 7',
          );
        }
      },
    );
  }

  static Future<void> insertTransaction(Transaction t) async {
    final db = await _database;
    await db.insert('transactions', t.toMap());
  }

  static Future<void> updateTransaction(Transaction t) async {
    final db = await _database;
    await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  static Future<List<Transaction>> getByYear(int year) async {
    final db = await _database;
    final rows = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        DateTime(year).toIso8601String(),
        DateTime(year + 1).toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  static Future<void> deleteTransaction(int id) async {
    final db = await _database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
