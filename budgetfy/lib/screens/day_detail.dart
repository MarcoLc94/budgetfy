import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../widgets/common/add_transaction_sheet.dart';

const _daysFull = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const _monthsFullDD = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const _neutralBlue = Color(0xFF3D7BF4);

class DayDetail extends StatefulWidget {
  final DateTime date;
  const DayDetail({super.key, required this.date});

  @override
  State<DayDetail> createState() => _DayDetailState();
}

class _DayDetailState extends State<DayDetail> {
  bool _showIncome = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final date = widget.date;
        final allDayTxs = finance.transactions
            .where((t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day)
            .toList();

        final income = allDayTxs
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final expenses = allDayTxs
            .where((t) => !t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final balance = income - expenses;

        final filteredTxs =
            allDayTxs.where((t) => t.isIncome == _showIncome).toList();

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              _buildDaySummaryCard(date, balance, income, expenses),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildToggle(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildTransactionList(filteredTxs, finance),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddTransactionSheet.show(
              context,
              finance,
              initialDate: date,
            ),
            backgroundColor:
                _showIncome ? AppColors.incomeGreen : AppColors.expenseRed,
            foregroundColor: _showIncome ? AppColors.darkBg : Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildDaySummaryCard(
      DateTime date, double balance, double income, double expenses) {
    final isPositive = balance > 0;
    final isNeutral = balance == 0;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dayName = _daysFull[date.weekday - 1];

    final Color themeColor = isNeutral
        ? _neutralBlue
        : (isPositive ? AppColors.incomeGreen : AppColors.expenseRed);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.65),
            themeColor.withValues(alpha: 0.25),
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
                'Balance — $dayName',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white30,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : ''}${fmt.format(balance)}',
            style: TextStyle(
              color: isPositive
                  ? AppColors.mintGreen
                  : (balance < 0 ? AppColors.expenseRed : Colors.white),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day} de ${_monthsFullDD[date.month - 1]} ${date.year}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DaySummaryPill(
                icon: Icons.arrow_upward_rounded,
                label: 'Ingresos',
                value: fmt.format(income),
                color: AppColors.incomeGreen,
              ),
              const SizedBox(width: 12),
              _DaySummaryPill(
                icon: Icons.arrow_downward_rounded,
                label: 'Gastos',
                value: fmt.format(expenses),
                color: AppColors.expenseRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _DayToggleOption(
            label: 'Ingreso',
            icon: Icons.arrow_upward_rounded,
            selected: _showIncome,
            color: AppColors.incomeGreen,
            onTap: () => setState(() => _showIncome = true),
          ),
          _DayToggleOption(
            label: 'Egreso',
            icon: Icons.arrow_downward_rounded,
            selected: !_showIncome,
            color: AppColors.expenseRed,
            onTap: () => setState(() => _showIncome = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      List<Transaction> txs, FinanceProvider finance) {
    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showIncome
                  ? Icons.savings_outlined
                  : Icons.receipt_long_outlined,
              size: 52,
              color: AppColors.divider,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin movimientos',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _showIncome
                  ? 'No hay ingresos registrados'
                  : 'No hay gastos registrados',
              style: const TextStyle(color: AppColors.divider, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: txs.length,
      itemBuilder: (context, i) =>
          _DayTxTile(transaction: txs[i], finance: finance),
    );
  }
}

// ─── Summary pill ─────────────────────────────────────────────────────────────

class _DaySummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DaySummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  Text(
                    value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle option ────────────────────────────────────────────────────────────

class _DayToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DayToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.textSecondary,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _DayTxTile extends StatelessWidget {
  final Transaction transaction;
  final FinanceProvider finance;
  const _DayTxTile({required this.transaction, required this.finance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final color =
        transaction.isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

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
        child: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
      ),
      onDismissed: (_) {
        if (transaction.id != null) finance.delete(transaction.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    transaction.category,
                    style: const TextStyle(
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
