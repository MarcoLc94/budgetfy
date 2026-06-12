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
      version: 4,
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
          recurring_interval INTEGER NOT NULL DEFAULT 7,
          recurring_group_id TEXT
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
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurring_group_id TEXT',
          );
          await _backfillRecurringGroups(db);
        }
      },
    );
  }

  /// Asigna un group id a los recurrentes existentes (creados antes de la
  /// versión 4), agrupándolos por sus campos comunes.
  static Future<void> _backfillRecurringGroups(Database db) async {
    final groups = await db.rawQuery('''
      SELECT DISTINCT description, amount, is_income, recurring_type, category
      FROM transactions WHERE is_recurring = 1
    ''');
    final batch = db.batch();
    var counter = 0;
    for (final g in groups) {
      final groupId = newRecurringGroupId(suffix: counter++);
      batch.update(
        'transactions',
        {'recurring_group_id': groupId},
        where: 'is_recurring = 1 AND description = ? AND amount = ? '
            'AND is_income = ? AND recurring_type = ? AND category = ?',
        whereArgs: [
          g['description'],
          g['amount'],
          g['is_income'],
          g['recurring_type'],
          g['category'],
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  static String newRecurringGroupId({int suffix = 0}) =>
      'rg_${DateTime.now().microsecondsSinceEpoch}_$suffix';

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

  static Future<void> deleteTransactions(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'transactions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Elimina todas las instancias de una serie recurrente por su group id.
  /// El fallback por campos comunes cubre filas legadas sin group id.
  static Future<void> deleteRecurringSeries(Transaction t) async {
    final db = await _database;
    if (t.recurringGroupId != null) {
      await db.delete(
        'transactions',
        where: 'recurring_group_id = ?',
        whereArgs: [t.recurringGroupId],
      );
      return;
    }
    await db.delete(
      'transactions',
      where: 'is_recurring = 1 AND recurring_group_id IS NULL '
          'AND description = ? AND amount = ? '
          'AND is_income = ? AND recurring_type = ? AND category = ?',
      whereArgs: [
        t.description,
        t.amount,
        t.isIncome ? 1 : 0,
        t.recurringType.name,
        t.category,
      ],
    );
  }
}
