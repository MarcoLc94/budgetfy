import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/add_transaction_sheet.dart';

class MonthDetail extends StatelessWidget {
  final int month;
  final int year;

  const MonthDetail({super.key, required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final data = finance.getMonthData(month);
        final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
        final grouped = _groupByDay(data.transactions);
        final sortedDays = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${s.monthsFull[month - 1]} $year',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              _buildMonthSummary(s, data, fmt),
              Expanded(
                child: data.isEmpty
                    ? _buildEmpty(context, finance)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: sortedDays.length,
                        itemBuilder: (context, i) {
                          final day = sortedDays[i];
                          final txs = grouped[day]!;
                          return _DaySection(day: day, transactions: txs);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddTransactionSheet.show(
              context,
              finance,
              initialDate: DateTime(year, month),
            ),
            backgroundColor: AppColors.primaryPurple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildMonthSummary(Strings s, MonthData data, NumberFormat fmt) {
    final balance = data.balance;
    final isPositive = balance >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: s.income,
              value: fmt.format(data.income),
              color: AppColors.incomeGreen,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: _SummaryItem(
              label: s.expenses,
              value: fmt.format(data.spending),
              color: AppColors.expenseRed,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: _SummaryItem(
              label: s.savings,
              value: fmt.format(data.savings),
              color: AppColors.savingsBlue,
              icon: Icons.savings_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: _SummaryItem(
              label: s.saldo,
              value: '${isPositive ? '+' : ''}${fmt.format(balance)}',
              color: isPositive ? AppColors.incomeGreen : AppColors.expenseRed,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, FinanceProvider finance) {
    final s = context.watch<SettingsProvider>().strings;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          Text(
            s.noTransactions,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            s.addForMonthHint,
            style: TextStyle(color: AppColors.divider, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => AddTransactionSheet.show(
              context,
              finance,
              initialDate: DateTime(year, month),
            ),
            icon: const Icon(Icons.add),
            label: Text(s.addTransaction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<Transaction> transactions;

  const _DaySection({required this.day, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dayTotal = transactions.fold(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );
    final isPositiveDay = dayTotal >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                _formatDay(s, day),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${isPositiveDay ? '+' : ''}${fmt.format(dayTotal)}',
                style: TextStyle(
                  color: isPositiveDay
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...transactions.map((t) => _TransactionTile(transaction: t)),
        const SizedBox(height: 4),
      ],
    );
  }

  String _formatDay(Strings s, DateTime d) =>
      '${s.daysShort[d.weekday - 1]}, ${d.day} ${s.monthsShort[d.month - 1].toLowerCase()}';
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final color =
        transaction.isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final provider = context.read<FinanceProvider>();

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.expenseRed),
      ),
      onDismissed: (_) {
        if (transaction.id != null) provider.delete(transaction.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transaction.isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    context
                        .watch<SettingsProvider>()
                        .strings
                        .categoryLabel(transaction.category),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
