import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import 'day_detail.dart';

/// Lista por día de los ingresos, egresos o ahorros de un mes, ordenada del
/// día 1 en adelante. Cada item navega al detalle del día con el tipo
/// correspondiente preseleccionado.
///
/// [category] filtra solo esa categoría (ej. Ahorro); [excludeCategory] la
/// excluye (ej. gastos sin ahorro).
class MonthTypeDetail extends StatelessWidget {
  final int month;
  final int year;
  final bool isIncome;
  final String? category;
  final String? excludeCategory;

  const MonthTypeDetail({
    super.key,
    required this.month,
    required this.year,
    required this.isIncome,
    this.category,
    this.excludeCategory,
  });

  bool get _isSavings => category == kSavingsCategory;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final s = settings.strings;

    final color = _isSavings
        ? AppColors.savingsBlue
        : (isIncome ? AppColors.incomeGreen : AppColors.expenseRed);
    final typeLabel =
        _isSavings ? s.savings : (isIncome ? s.income : s.expensesPlural);

    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final monthTxs = finance
            .getMonthData(month)
            .transactions
            .where((t) =>
                t.isIncome == isIncome &&
                (category == null || t.category == category) &&
                (excludeCategory == null || t.category != excludeCategory))
            .toList();

        final grouped = _groupByDay(monthTxs);
        final sortedDays = grouped.keys.toList()..sort();

        final total = monthTxs.fold(0.0, (s, t) => s + t.amount);
        final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '$typeLabel — ${s.monthsFull[month - 1]} $year',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Column(
            children: [
              _buildSummaryCard(
                  settings, color, typeLabel, total, monthTxs.length, fmt),
              const SizedBox(height: 8),
              Expanded(
                child: sortedDays.isEmpty
                    ? _buildEmpty(s, typeLabel)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: sortedDays.length,
                        itemBuilder: (context, i) {
                          final day = sortedDays[i];
                          final txs = grouped[day]!;
                          return _DayItem(
                            day: day,
                            transactions: txs,
                            color: color,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayDetail(
                                  date: day,
                                  initialShowIncome: isIncome,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    SettingsProvider settings,
    Color color,
    String typeLabel,
    double total,
    int count,
    NumberFormat fmt,
  ) {
    final s = settings.strings;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.65),
            color.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${s.total} $typeLabel',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Icon(
                _isSavings
                    ? Icons.savings_outlined
                    : (isIncome
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded),
                color: Colors.white30,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt.format(total)} ${settings.currency}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.movementsInMonth(count, s.monthsFull[month - 1].toLowerCase()),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Strings s, String typeLabel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSavings || isIncome
                ? Icons.savings_outlined
                : Icons.receipt_long_outlined,
            size: 52,
            color: AppColors.divider,
          ),
          const SizedBox(height: 12),
          Text(
            s.noMovements,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            s.noTypeThisMonth(typeLabel),
            style: TextStyle(color: AppColors.divider, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupByDay(List<Transaction> txs) {
    final Map<DateTime, List<Transaction>> map = {};
    for (final t in txs) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }
}

// ─── Day item ─────────────────────────────────────────────────────────────────

class _DayItem extends StatelessWidget {
  final DateTime day;
  final List<Transaction> transactions;
  final Color color;
  final VoidCallback onTap;

  const _DayItem({
    required this.day,
    required this.transactions,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final sum = transactions.fold(0.0, (s, t) => s + t.amount);
    final count = transactions.length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              // Day number badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      s.daysShort[day.weekday - 1],
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? transactions.first.description
                          : s.nMovements(count),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      count == 1
                          ? s.categoryLabel(transactions.first.category)
                          : s.tapForDetail,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fmt.format(sum),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: AppColors.divider,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
