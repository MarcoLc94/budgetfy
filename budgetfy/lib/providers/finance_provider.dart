import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class WeekData {
  final DateTime start;
  final DateTime end;
  final List<Transaction> transactions;

  const WeekData({
    required this.start,
    required this.end,
    required this.transactions,
  });

  double get income => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get expenses => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get balance => income - expenses;
  bool get isEmpty => transactions.isEmpty;
}

class MonthData {
  final int month;
  final List<Transaction> transactions;

  const MonthData({required this.month, required this.transactions});

  double get income => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get expenses => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Egresos con categoría Ahorro: restan del balance (no están disponibles)
  /// pero se muestran aparte de los gastos.
  double get savings => transactions
      .where((t) => !t.isIncome && t.category == kSavingsCategory)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Gastos reales, sin contar el ahorro.
  double get spending => expenses - savings;

  double get balance => income - expenses;

  bool get isEmpty => transactions.isEmpty;
}

/// Serie recurrente: todas las instancias generadas por un mismo movimiento
/// recurrente (agrupadas por descripción, monto, tipo y frecuencia).
class RecurringGroup {
  final Transaction sample;
  final List<Transaction> instances;

  const RecurringGroup({required this.sample, required this.instances});

  int get count => instances.length;
  double get total => instances.fold(0.0, (s, t) => s + t.amount);
}

class FinanceProvider extends ChangeNotifier {
  int _year = DateTime.now().year;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  int get year => _year;
  bool get isLoading => _isLoading;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get yearBalance => totalIncome - totalExpenses;

  List<MonthData> get monthsData => List.generate(
    12,
    (i) => MonthData(
      month: i + 1,
      transactions: _transactions.where((t) => t.date.month == i + 1).toList(),
    ),
  );

  List<WeekData> get weeksData {
    final jan1 = DateTime(_year, 1, 1);
    final offset = jan1.weekday - 1;
    var weekStart = jan1.subtract(Duration(days: offset));
    final dec31 = DateTime(_year, 12, 31);
    final weeks = <WeekData>[];

    while (!weekStart.isAfter(dec31)) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final txs = _transactions.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
      }).toList();
      weeks.add(WeekData(start: weekStart, end: weekEnd, transactions: txs));
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return weeks;
  }

  MonthData getMonthData(int month) => MonthData(
    month: month,
    transactions: _transactions
        .where((t) => t.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)),
  );

  Future<void> loadYear(int year) async {
    _isLoading = true;
    _year = year;
    notifyListeners();
    try {
      _transactions = List<Transaction>.from(await DatabaseService.getByYear(year));
    } catch (_) {
      _transactions = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(Transaction t) async {
    if (t.isRecurring) {
      final groupId =
          t.recurringGroupId ?? DatabaseService.newRecurringGroupId();
      for (final date in _recurringDates(t)) {
        await DatabaseService.insertTransaction(
          t.copyWith(date: date, recurringGroupId: groupId),
        );
      }
    } else {
      await DatabaseService.insertTransaction(t);
    }
    await loadYear(_year);
  }

  List<DateTime> _recurringDates(Transaction t) {
    final year = t.date.year;
    final start = DateTime(t.date.year, t.date.month, t.date.day);
    final end = DateTime(year, 12, 31);

    switch (t.recurringType) {
      case RecurringType.daily:
        final dates = <DateTime>[];
        var d = start;
        while (!d.isAfter(end)) {
          dates.add(d);
          d = d.add(const Duration(days: 1));
        }
        return dates;

      case RecurringType.weekly:
        final dates = <DateTime>[];
        var d = start;
        while (!d.isAfter(end)) {
          dates.add(d);
          d = d.add(const Duration(days: 7));
        }
        return dates;

      case RecurringType.monthly:
        return List.generate(12, (i) {
          final month = i + 1;
          final lastDay = DateTime(year, month + 1, 0).day;
          final day = t.date.day.clamp(1, lastDay);
          return DateTime(year, month, day);
        });

      case RecurringType.custom:
        final interval = t.recurringIntervalDays > 0 ? t.recurringIntervalDays : 1;
        final dates = <DateTime>[];
        var d = start;
        while (!d.isAfter(end)) {
          dates.add(d);
          d = d.add(Duration(days: interval));
        }
        return dates;
    }
  }

  Future<void> update(Transaction t) async {
    await DatabaseService.updateTransaction(t);
    await loadYear(_year);
  }

  Future<void> delete(int id) async {
    await DatabaseService.deleteTransaction(id);
    await loadYear(_year);
  }

  Future<void> deleteMany(List<int> ids) async {
    await DatabaseService.deleteTransactions(ids);
    await loadYear(_year);
  }

  /// Series recurrentes del año cargado, agrupadas por su group id. Las filas
  /// legadas sin group id se agrupan por sus campos comunes.
  List<RecurringGroup> get recurringGroups {
    final Map<String, List<Transaction>> map = {};
    for (final t in _transactions.where((t) => t.isRecurring)) {
      final key = t.recurringGroupId ??
          'legacy|${t.description}|${t.amount}|${t.isIncome}|'
              '${t.recurringType.name}|${t.category}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final groups = map.values
        .map((txs) {
          txs.sort((a, b) => a.date.compareTo(b.date));
          return RecurringGroup(sample: txs.first, instances: txs);
        })
        .toList()
      ..sort((a, b) => a.sample.description
          .toLowerCase()
          .compareTo(b.sample.description.toLowerCase()));
    return groups;
  }

  /// Elimina todas las instancias de una serie recurrente.
  Future<void> deleteRecurringSeries(Transaction sample) async {
    await DatabaseService.deleteRecurringSeries(sample);
    await loadYear(_year);
  }
}
