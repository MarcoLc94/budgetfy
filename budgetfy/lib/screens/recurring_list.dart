import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';

/// Lista de series recurrentes del año cargado. Permite eliminar una serie
/// completa (todas sus instancias) de un solo paso.
class RecurringList extends StatelessWidget {
  const RecurringList({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final groups = finance.recurringGroups;

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
              '${s.recurring} ${finance.year}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: groups.isEmpty
              ? _buildEmpty(s)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, i) => _RecurringCard(
                    group: groups[i],
                    onDelete: () => _confirmAndDelete(
                      context,
                      finance,
                      groups[i],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmpty(Strings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat_rounded, size: 52, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            s.noRecurring,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            s.recurringHint,
            style: TextStyle(color: AppColors.divider, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    FinanceProvider finance,
    RecurringGroup group,
  ) async {
    final s = context.read<SettingsProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          s.deleteSeriesTitle,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          s.deleteSeriesBody(group.sample.description, group.count),
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
              s.deleteEverything,
              style: TextStyle(
                color: AppColors.expenseRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await finance.deleteRecurringSeries(group.sample);
    }
  }
}

// ─── Recurring series card ────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final RecurringGroup group;
  final VoidCallback onDelete;

  const _RecurringCard({required this.group, required this.onDelete});

  String _shortDate(Strings s, DateTime d) =>
      '${d.day} ${s.monthsShort[d.month - 1].toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final t = group.sample;
    final color = t.isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final first = group.instances.first.date;
    final last = group.instances.last.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.repeat_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${s.categoryLabel(t.category)} · ${s.frequencyLabel(t)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${t.isIncome ? '+' : '-'}${fmt.format(t.amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.tag_rounded,
                label: s.timesCount(group.count),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.date_range_outlined,
                label: '${_shortDate(s, first)} — ${_shortDate(s, last)}',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.functions_rounded,
                label: fmt.format(group.total),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.expenseRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.expenseRed.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: AppColors.expenseRed,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.delete,
                        style: TextStyle(
                          color: AppColors.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
