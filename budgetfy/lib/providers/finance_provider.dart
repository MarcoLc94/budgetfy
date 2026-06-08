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

  double get balance => income - expenses;

  bool get isEmpty => transactions.isEmpty;
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
      final year = t.date.year;
      for (int month = 1; month <= 12; month++) {
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = t.date.day.clamp(1, lastDay);
        await DatabaseService.insertTransaction(
          t.copyWith(date: DateTime(year, month, day)),
        );
      }
    } else {
      await DatabaseService.insertTransaction(t);
    }
    await loadYear(_year);
  }

  Future<void> delete(int id) async {
    await DatabaseService.deleteTransaction(id);
    await loadYear(_year);
  }
}
