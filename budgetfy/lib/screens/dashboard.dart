import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../widgets/common/add_transaction_sheet.dart';
import 'day_detail.dart';
import 'month_detail.dart';

const _monthsShort = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _monthsFull = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const _neutralBlue = Color(0xFF3D7BF4);
const _weekendAmber = Color(0xFFFFB347);

enum _ViewMode { monthly, weekly }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  _ViewMode _viewMode = _ViewMode.weekly;

  // Summary card
  late PageController _summaryController;
  int _summaryMonth = DateTime.now().month;

  // Weekly view
  PageController? _weekController;
  int _weekControllerYear = 0;
  int _currentWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _summaryController = PageController(initialPage: _summaryMonth - 1);
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _weekController?.dispose();
    super.dispose();
  }

  PageController _getWeekController(List<WeekData> weeks, int year) {
    if (_weekController != null && _weekControllerYear == year) {
      return _weekController!;
    }
    _weekController?.dispose();
    _weekControllerYear = year;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int idx = weeks.indexWhere(
      (w) => !todayDate.isBefore(w.start) && !todayDate.isAfter(w.end),
    );
    _currentWeekIndex = idx.clamp(0, weeks.isEmpty ? 0 : weeks.length - 1);
    _weekController = PageController(initialPage: _currentWeekIndex);
    return _weekController!;
  }

  void _toggleView() {
    setState(() {
      _viewMode = _viewMode == _ViewMode.monthly
          ? _ViewMode.weekly
          : _ViewMode.monthly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final weeks = finance.weeksData;
        final controller =
            _viewMode == _ViewMode.weekly && weeks.isNotEmpty
                ? _getWeekController(weeks, finance.year)
                : null;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(finance, weeks, controller),
              SliverToBoxAdapter(
                child: _buildSummaryCard(finance, weeks),
              ),
              if (_viewMode == _ViewMode.monthly)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: _buildMonthGrid(finance),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: _buildWeekPageView(finance, weeks, controller),
                ),
            ],
          ),
          floatingActionButton: _viewMode == _ViewMode.monthly
              ? FloatingActionButton.extended(
                  onPressed: () => AddTransactionSheet.show(context, finance),
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }

  SliverAppBar _buildAppBar(
    FinanceProvider finance,
    List<WeekData> weeks,
    PageController? controller,
  ) {
    final isMonthly = _viewMode == _ViewMode.monthly;
    return SliverAppBar(
      backgroundColor: AppColors.darkBg,
      pinned: true,
      title: Row(
        children: [
          const Text(
            'Budgetfy',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleView,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMonthly
                    ? AppColors.primaryPurple.withValues(alpha: 0.25)
                    : AppColors.mintGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMonthly
                      ? AppColors.primaryPurple.withValues(alpha: 0.6)
                      : AppColors.mintGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMonthly
                        ? Icons.calendar_month_outlined
                        : Icons.calendar_view_week_outlined,
                    size: 13,
                    color: isMonthly
                        ? AppColors.lightPurple
                        : AppColors.mintGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isMonthly ? 'Mensual' : 'Semanal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMonthly
                          ? AppColors.lightPurple
                          : AppColors.mintGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (isMonthly)
            _YearSelector(finance: finance)
          else
            _WeekMonthLabel(
              weeks: weeks,
              currentIndex: _currentWeekIndex,
              controller: controller,
              onPageChange: (i) => setState(() => _currentWeekIndex = i),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(FinanceProvider finance, List<WeekData> weeks) {
    if (_viewMode == _ViewMode.weekly && weeks.isNotEmpty) {
      return _buildWeeklySummaryCard(weeks, finance);
    }

    // Monthly mode — swipeable 12-month card
    final yearBalance = finance.yearBalance;
    final isYearPositive = yearBalance >= 0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _summaryController,
            itemCount: 12,
            onPageChanged: (i) => setState(() => _summaryMonth = i + 1),
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthData = finance.getMonthData(month);
              final monthBalance = monthData.balance;
              final isPositive = monthBalance >= 0;
              final fmt =
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2);

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.8),
                      AppColors.primaryPurple.withValues(alpha: 0.4),
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
                          'Balance — ${_monthsFull[month - 1]}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const Spacer(),
                        const Icon(Icons.swipe_outlined,
                            color: Colors.white30, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${isPositive ? '+' : ''}${fmt.format(monthBalance)}',
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.mintGreen
                            : AppColors.expenseRed,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Anual: ${isYearPositive ? '+' : ''}${fmt.format(yearBalance)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SummaryPill(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Ingresos',
                          value: fmt.format(monthData.income),
                          color: AppColors.incomeGreen,
                        ),
                        const SizedBox(width: 12),
                        _SummaryPill(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Gastos',
                          value: fmt.format(monthData.expenses),
                          color: AppColors.expenseRed,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _MonthDots(currentIndex: _summaryMonth - 1),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(List<WeekData> weeks, FinanceProvider finance) {
    final week = weeks[_currentWeekIndex];
    // Use Thursday to determine the representative month (ISO standard)
    final thursday = week.start.add(const Duration(days: 3));
    final monthName = _monthsFull[thursday.month - 1].toUpperCase();
    final year = thursday.year;

    // Week range label
    final startDay = week.start.day;
    final endDay = week.end.day;
    final startMonth = _monthsFull[week.start.month - 1].toLowerCase();
    final endMonth = _monthsFull[week.end.month - 1].toLowerCase();
    final rangeLabel = week.start.month == week.end.month
        ? '$startDay — $endDay de $startMonth'
        : '$startDay $startMonth — $endDay $endMonth';

    // Monthly balance for the representative month
    final monthData = finance.getMonthData(thursday.month);
    final monthBalance = monthData.balance;
    final isPositive = monthBalance >= 0;

    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.8),
            AppColors.primaryPurple.withValues(alpha: 0.4),
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
                'Balance — $monthName',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_view_week_outlined,
                color: Colors.white30,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : ''}${fmt.format(monthBalance)}',
            style: TextStyle(
              color: isPositive ? AppColors.mintGreen : AppColors.expenseRed,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$year',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                rangeLabel,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryPill(
                icon: Icons.arrow_upward_rounded,
                label: 'Ingresos',
                value: fmt.format(monthData.income),
                color: AppColors.incomeGreen,
              ),
              const SizedBox(width: 12),
              _SummaryPill(
                icon: Icons.arrow_downward_rounded,
                label: 'Gastos',
                value: fmt.format(monthData.expenses),
                color: AppColors.expenseRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(FinanceProvider finance) {
    final now = DateTime.now();
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final monthData = finance.monthsData[index];
          final isCurrent =
              monthData.month == now.month && finance.year == now.year;
          return _MonthCard(
            monthIndex: index,
            monthData: monthData,
            isCurrent: isCurrent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthDetail(
                  month: monthData.month,
                  year: finance.year,
                ),
              ),
            ),
          );
        },
        childCount: 12,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
    );
  }

  Widget _buildWeekPageView(
    FinanceProvider finance,
    List<WeekData> weeks,
    PageController? controller,
  ) {
    if (weeks.isEmpty || controller == null) {
      return const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return PageView.builder(
      controller: controller,
      itemCount: weeks.length,
      onPageChanged: (i) => setState(() => _currentWeekIndex = i),
      itemBuilder: (context, index) => _WeekPage(week: weeks[index]),
    );
  }
}

// ─── Week month label in app bar ─────────────────────────────────────────────

class _WeekMonthLabel extends StatelessWidget {
  final List<WeekData> weeks;
  final int currentIndex;
  final PageController? controller;
  final void Function(int) onPageChange;

  const _WeekMonthLabel({
    required this.weeks,
    required this.currentIndex,
    required this.controller,
    required this.onPageChange,
  });

  String get _label {
    if (weeks.isEmpty) return '';
    final week = weeks[currentIndex];
    final thursday = week.start.add(const Duration(days: 3));
    return '${_monthsFull[thursday.month - 1]} ${thursday.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowBtn(
          icon: Icons.chevron_left,
          onTap: currentIndex > 0
              ? () {
                  controller?.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _ArrowBtn(
          icon: Icons.chevron_right,
          onTap: currentIndex < weeks.length - 1
              ? () {
                  controller?.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
        ),
      ],
    );
  }
}

// ─── Week page (7 day cards) ─────────────────────────────────────────────────

class _WeekPage extends StatelessWidget {
  final WeekData week;
  const _WeekPage({required this.week});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      child: Column(
        children: List.generate(7, (i) {
          final date = week.start.add(Duration(days: i));
          final dayTxs = week.transactions
              .where(
                (t) =>
                    t.date.year == date.year &&
                    t.date.month == date.month &&
                    t.date.day == date.day,
              )
              .toList();
          final isToday = date == today;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _DayCard(
                date: date,
                transactions: dayTxs,
                isToday: isToday,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Day card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final bool isToday;

  const _DayCard({
    required this.date,
    required this.transactions,
    required this.isToday,
  });

  double get income =>
      transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get expenses =>
      transactions.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get balance => income - expenses;

  bool get isWeekend => date.weekday == 6 || date.weekday == 7;

  Color _bgColor(bool isToday) {
    if (isToday) return AppColors.primaryPurple.withValues(alpha: 0.15);
    if (balance > 0) return AppColors.incomeGreen.withValues(alpha: 0.08);
    if (balance < 0) return AppColors.expenseRed.withValues(alpha: 0.08);
    return _neutralBlue.withValues(alpha: 0.07);
  }

  Color _borderColor(bool isToday) {
    if (isToday) return AppColors.primaryPurple;
    if (balance > 0) return AppColors.incomeGreen.withValues(alpha: 0.45);
    if (balance < 0) return AppColors.expenseRed.withValues(alpha: 0.45);
    return _neutralBlue.withValues(alpha: 0.3);
  }

  Color _balanceColor() {
    if (balance > 0) return AppColors.incomeGreen;
    if (balance < 0) return AppColors.expenseRed;
    return _neutralBlue;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);
    final dayNameColor =
        isToday ? AppColors.mintGreen : (isWeekend ? _weekendAmber : AppColors.textSecondary);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DayDetail(date: date)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _bgColor(isToday),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor(isToday),
            width: isToday ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Day name + number
            SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayNames[date.weekday - 1],
                    style: TextStyle(
                      color: dayNameColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isToday ? Colors.white : AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          _monthsShort[date.month - 1],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Balance
            Text(
              transactions.isEmpty
                  ? '—'
                  : '${balance >= 0 ? '+' : ''}${fmt.format(balance)}',
              style: TextStyle(
                color: transactions.isEmpty
                    ? AppColors.divider
                    : _balanceColor(),
                fontSize: 15,
                fontWeight: FontWeight.bold,
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
    );
  }
}

// ─── Month dots indicator ─────────────────────────────────────────────────────

class _MonthDots extends StatelessWidget {
  final int currentIndex;
  const _MonthDots({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? AppColors.mintGreen : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _YearSelector extends StatelessWidget {
  final FinanceProvider finance;
  const _YearSelector({required this.finance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowBtn(
          icon: Icons.chevron_left,
          onTap: () => finance.loadYear(finance.year - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${finance.year}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _ArrowBtn(
          icon: Icons.chevron_right,
          onTap: () => finance.loadYear(finance.year + 1),
        ),
      ],
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.cardBg
              : AppColors.cardBg.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppColors.textSecondary : AppColors.divider,
          size: 20,
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryPill({
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

class _MonthCard extends StatelessWidget {
  final int monthIndex;
  final MonthData monthData;
  final bool isCurrent;
  final VoidCallback onTap;
  const _MonthCard({
    required this.monthIndex,
    required this.monthData,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final balance = monthData.balance;
    final isPositive = balance >= 0;
    final hasData = !monthData.isEmpty;
    final fmt = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isCurrent
              ? Border.all(color: AppColors.primaryPurple, width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthsShort[monthIndex],
                  style: TextStyle(
                    color: isCurrent
                        ? AppColors.mintGreen
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'HOY',
                      style: TextStyle(
                          color: AppColors.mintGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              hasData
                  ? '${isPositive ? '+' : ''}${fmt.format(balance)}'
                  : '--',
              style: TextStyle(
                color: hasData
                    ? (isPositive ? AppColors.incomeGreen : AppColors.expenseRed)
                    : AppColors.divider,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (hasData) _buildBar(monthData) else const SizedBox(height: 4),
            const SizedBox(height: 6),
            Row(
              children: [
                _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  value: hasData ? fmt.format(monthData.income) : '-',
                  color: AppColors.incomeGreen,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  value: hasData ? fmt.format(monthData.expenses) : '-',
                  color: AppColors.expenseRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(MonthData data) {
    final total = data.income + data.expenses;
    if (total == 0) return const SizedBox(height: 4);
    final incomeFraction = (data.income / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(
              height: 4,
              color: AppColors.expenseRed.withValues(alpha: 0.3)),
          FractionallySizedBox(
            widthFactor: incomeFraction,
            child: Container(height: 4, color: AppColors.incomeGreen),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
