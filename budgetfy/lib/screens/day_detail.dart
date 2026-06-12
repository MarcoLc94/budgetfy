import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/add_transaction_sheet.dart';

const _neutralBlue = Color(0xFF3D7BF4);

class DayDetail extends StatefulWidget {
  final DateTime date;
  final bool initialShowIncome;
  const DayDetail({super.key, required this.date, this.initialShowIncome = true});

  @override
  State<DayDetail> createState() => _DayDetailState();
}

class _DayDetailState extends State<DayDetail> {
  late bool _showIncome = widget.initialShowIncome;
  final Set<int> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(int id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  Future<bool> _confirmDelete(int count) async {
    final s = context.read<SettingsProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          s.deleteMovementsTitle,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          s.deleteMovementsBody(count),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: TextStyle(
                color: AppColors.expenseRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteSelected(FinanceProvider finance) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    if (!await _confirmDelete(ids.length)) return;
    setState(() => _selectedIds.clear());
    await finance.deleteMany(ids);
  }

  Future<void> _deleteAll(
      FinanceProvider finance, List<Transaction> txs) async {
    final ids = txs.map((t) => t.id).whereType<int>().toList();
    if (ids.isEmpty) return;
    if (!await _confirmDelete(ids.length)) return;
    setState(() => _selectedIds.clear());
    await finance.deleteMany(ids);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final s = settings.strings;
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
        final savings = allDayTxs
            .where((t) => !t.isIncome && t.category == kSavingsCategory)
            .fold(0.0, (s, t) => s + t.amount);
        final balance = income - expenses;

        final filteredTxs =
            allDayTxs.where((t) => t.isIncome == _showIncome).toList();

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: _selectionMode
              ? _buildSelectionAppBar(finance, filteredTxs)
              : AppBar(
                  backgroundColor: AppColors.darkBg,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (filteredTxs.isNotEmpty)
                      IconButton(
                        tooltip: s.deleteAllTooltip,
                        icon: Icon(
                          Icons.delete_sweep_outlined,
                          color: AppColors.expenseRed,
                        ),
                        onPressed: () => _deleteAll(finance, filteredTxs),
                      ),
                  ],
                ),
          body: Column(
            children: [
              _buildDaySummaryCard(
                  settings, date, balance, income, expenses, savings),
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
          floatingActionButton: _selectionMode
              ? null
              : FloatingActionButton(
                  onPressed: () => AddTransactionSheet.show(
                    context,
                    finance,
                    initialDate: date,
                  ),
                  backgroundColor: _showIncome
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                  foregroundColor:
                      _showIncome ? AppColors.darkBg : Colors.white,
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  AppBar _buildSelectionAppBar(
      FinanceProvider finance, List<Transaction> filteredTxs) {
    final s = context.read<SettingsProvider>().strings;
    final allSelected = filteredTxs.isNotEmpty &&
        filteredTxs.every((t) => _selectedIds.contains(t.id));

    return AppBar(
      backgroundColor: AppColors.darkBg,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.textPrimary),
        tooltip: s.cancelSelection,
        onPressed: () => setState(() => _selectedIds.clear()),
      ),
      title: Text(
        s.selectedCount(_selectedIds.length),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          tooltip: allSelected ? s.deselectAll : s.selectAll,
          icon: Icon(
            allSelected ? Icons.deselect : Icons.select_all,
            color: AppColors.textPrimary,
          ),
          onPressed: () => setState(() {
            if (allSelected) {
              _selectedIds.clear();
            } else {
              _selectedIds
                  .addAll(filteredTxs.map((t) => t.id).whereType<int>());
            }
          }),
        ),
        IconButton(
          tooltip: s.deleteSelected,
          icon: Icon(Icons.delete_outline, color: AppColors.expenseRed),
          onPressed: () => _deleteSelected(finance),
        ),
      ],
    );
  }

  Widget _buildDaySummaryCard(SettingsProvider settings, DateTime date,
      double balance, double income, double expenses, double savings) {
    final s = settings.strings;
    final isPositive = balance > 0;
    final isNeutral = balance == 0;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dayName = s.daysFull[date.weekday - 1];

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
                '${s.balance} — $dayName',
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
            s.longDate(date),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DaySummaryPill(
                icon: Icons.arrow_upward_rounded,
                label: s.income,
                value: fmt.format(income),
                color: AppColors.incomeGreen,
              ),
              const SizedBox(width: 8),
              _DaySummaryPill(
                icon: Icons.arrow_downward_rounded,
                label: s.expenses,
                value: fmt.format(expenses - savings),
                color: AppColors.expenseRed,
              ),
              const SizedBox(width: 8),
              _DaySummaryPill(
                icon: Icons.savings_outlined,
                label: '${s.savings} (${settings.currency})',
                value: fmt.format(savings),
                color: AppColors.savingsBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    final s = context.watch<SettingsProvider>().strings;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _DayToggleOption(
            label: s.incomeSingular,
            icon: Icons.arrow_upward_rounded,
            selected: _showIncome,
            color: AppColors.incomeGreen,
            onTap: () => setState(() {
              _showIncome = true;
              _selectedIds.clear();
            }),
          ),
          _DayToggleOption(
            label: s.expenseSingular,
            icon: Icons.arrow_downward_rounded,
            selected: !_showIncome,
            color: AppColors.expenseRed,
            onTap: () => setState(() {
              _showIncome = false;
              _selectedIds.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      List<Transaction> txs, FinanceProvider finance) {
    final s = context.watch<SettingsProvider>().strings;
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
            Text(
              s.noMovements,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _showIncome ? s.noIncomeRegistered : s.noExpensesRegistered,
              style: TextStyle(color: AppColors.divider, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: txs.length,
      itemBuilder: (context, i) {
        final tx = txs[i];
        return _DayTxTile(
          transaction: tx,
          finance: finance,
          selectionMode: _selectionMode,
          selected: tx.id != null && _selectedIds.contains(tx.id),
          onLongPress: () {
            if (tx.id != null && !_selectionMode) _toggleSelection(tx.id!);
          },
          onSelectionToggle: () {
            if (tx.id != null) _toggleSelection(tx.id!);
          },
        );
      },
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
  final bool selectionMode;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onSelectionToggle;

  const _DayTxTile({
    required this.transaction,
    required this.finance,
    required this.selectionMode,
    required this.selected,
    required this.onLongPress,
    required this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final color =
        transaction.isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction:
          selectionMode ? DismissDirection.none : DismissDirection.endToStart,
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
        if (transaction.id != null) finance.delete(transaction.id!);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: onLongPress,
          onTap: selectionMode
              ? onSelectionToggle
              : () => AddTransactionSheet.show(
                    context,
                    finance,
                    initialTransaction: transaction,
                  ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryPurple.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primaryPurple
                    : color.withValues(alpha: 0.18),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryPurple.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selected
                        ? Icons.check_rounded
                        : (transaction.isIncome
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded),
                    color: selected ? AppColors.mintGreen : color,
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
                      Row(
                        children: [
                          if (transaction.isRecurring) ...[
                            Icon(
                              Icons.repeat_rounded,
                              color: AppColors.textSecondary,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                          ],
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
                const SizedBox(width: 4),
                Icon(
                  selectionMode
                      ? (selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked)
                      : Icons.edit_outlined,
                  color: selected
                      ? AppColors.primaryPurple
                      : AppColors.divider,
                  size: selectionMode ? 18 : 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
