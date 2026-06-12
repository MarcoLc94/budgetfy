import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/settings_provider.dart';

const _incomeCategories = ['Salario', 'Freelance', 'Inversión', 'Bono', 'Otro'];
const _expenseCategories = [
  'Comida',
  'Transporte',
  'Vivienda',
  'Entretenimiento',
  'Salud',
  'Compras',
  'Educación',
  'Servicios',
  kSavingsCategory,
  'Otro',
];

class AddTransactionSheet extends StatefulWidget {
  final FinanceProvider provider;
  final DateTime? initialDate;
  final Transaction? initialTransaction;

  const AddTransactionSheet({
    super.key,
    required this.provider,
    this.initialDate,
    this.initialTransaction,
  });

  static Future<void> show(
    BuildContext context,
    FinanceProvider provider, {
    DateTime? initialDate,
    Transaction? initialTransaction,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        provider: provider,
        initialDate: initialDate,
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _intervalController = TextEditingController(text: '7');

  bool _isIncome = false;
  late DateTime _selectedDate;
  String _selectedCategory = _expenseCategories.first;
  bool _isRecurring = false;
  RecurringType _recurringType = RecurringType.monthly;
  bool _saving = false;

  bool get _isEditMode => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTransaction;
    if (t != null) {
      _descController.text = t.description;
      _amountController.text = t.amount.toStringAsFixed(
        t.amount.truncateToDouble() == t.amount ? 0 : 2,
      );
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      final cats = t.isIncome ? _incomeCategories : _expenseCategories;
      _selectedCategory = cats.contains(t.category) ? t.category : cats.first;
      _isRecurring = t.isRecurring;
      _recurringType = t.recurringType;
      _intervalController.text = t.recurringIntervalDays.toString();
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _toggleType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _selectedCategory =
          isIncome ? _incomeCategories.first : _expenseCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primaryPurple,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (desc.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.read<SettingsProvider>().strings.fillAllFields),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    if (_isEditMode) {
      await widget.provider.update(
        widget.initialTransaction!.copyWith(
          description: desc,
          amount: amount,
          isIncome: _isIncome,
          date: _selectedDate,
          category: _selectedCategory,
        ),
      );
    } else {
      final interval = int.tryParse(_intervalController.text) ?? 7;
      await widget.provider.add(
        Transaction(
          description: desc,
          amount: amount,
          isIncome: _isIncome,
          date: _selectedDate,
          category: _selectedCategory,
          isRecurring: _isRecurring,
          recurringType: _recurringType,
          recurringIntervalDays: interval > 0 ? interval : 1,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final s = context.read<SettingsProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.deleteTransaction,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          s.deleteTransactionConfirm,
          style: TextStyle(color: AppColors.textSecondary),
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
              style: TextStyle(color: AppColors.expenseRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final id = widget.initialTransaction!.id;
      if (id != null) await widget.provider.delete(id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditMode ? s.editTransaction : s.newTransaction,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _TypeToggle(isIncome: _isIncome, onToggle: _toggleType),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: s.description),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: s.amount,
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(date: _selectedDate, onTap: _pickDate),
            if (!_isEditMode) ...[
              const SizedBox(height: 12),
              _RecurringToggle(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isRecurring
                    ? _RecurringOptions(
                        selectedType: _recurringType,
                        onTypeChanged: (t) =>
                            setState(() => _recurringType = t),
                        intervalController: _intervalController,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              s.category,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (cat) => _CategoryChip(
                      label: s.categoryLabel(cat),
                      selected: cat == _selectedCategory,
                      isIncome: _isIncome,
                      isSavings: cat == kSavingsCategory,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome
                      ? AppColors.incomeGreen
                      : AppColors.primaryPurple,
                  foregroundColor: _isIncome
                      ? AppColors.darkBg
                      : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditMode ? s.update : s.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _confirmDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.expenseRed,
                    size: 18,
                  ),
                  label: Text(
                    s.deleteTransaction,
                    style: TextStyle(color: AppColors.expenseRed),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Type toggle ──────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool isIncome;
  final void Function(bool) onToggle;

  const _TypeToggle({required this.isIncome, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>().strings;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: s.expenseToggle,
            icon: Icons.arrow_downward_rounded,
            selected: !isIncome,
            color: AppColors.expenseRed,
            onTap: () => onToggle(false),
          ),
          _ToggleOption(
            label: s.incomeToggle,
            icon: Icons.arrow_upward_rounded,
            selected: isIncome,
            color: AppColors.incomeGreen,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleOption({
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
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.textSecondary, size: 18),
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

// ─── Date field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.watch<SettingsProvider>().strings.longDate(date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recurring toggle ─────────────────────────────────────────────────────────

class _RecurringToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _RecurringToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryPurple.withValues(alpha: 0.12)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppColors.primaryPurple.withValues(alpha: 0.6)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              color: value ? AppColors.lightPurple : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.watch<SettingsProvider>().strings.recurrente,
                style: TextStyle(
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primaryPurple,
              checkColor: Colors.white,
              side: BorderSide(
                color: value ? AppColors.primaryPurple : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recurring options (expanded when toggle is on) ───────────────────────────

String _recurringLabel(BuildContext context, RecurringType type) {
  final s = context.read<SettingsProvider>().strings;
  switch (type) {
    case RecurringType.daily:
      return s.isEn ? 'Daily' : 'Diario';
    case RecurringType.weekly:
      return s.weekly;
    case RecurringType.monthly:
      return s.monthly;
    case RecurringType.custom:
      return s.custom;
  }
}

class _RecurringOptions extends StatelessWidget {
  final RecurringType selectedType;
  final void Function(RecurringType) onTypeChanged;
  final TextEditingController intervalController;

  const _RecurringOptions({
    required this.selectedType,
    required this.onTypeChanged,
    required this.intervalController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: RecurringType.values.map((type) {
            final selected = selectedType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => onTypeChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryPurple.withValues(alpha: 0.2)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryPurple.withValues(alpha: 0.7)
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      _recurringLabel(context, type),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? AppColors.lightPurple
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedType == RecurringType.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                context.watch<SettingsProvider>().strings.every,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                height: 40,
                child: TextField(
                  controller: intervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.watch<SettingsProvider>().strings.days,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isIncome;
  final bool isSavings;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.isIncome,
    this.isSavings = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSavings
        ? AppColors.savingsBlue
        : (isIncome ? AppColors.incomeGreen : AppColors.primaryPurple);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
