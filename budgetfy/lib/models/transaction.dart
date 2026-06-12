enum RecurringType { daily, weekly, monthly, custom }

/// Nombre canónico de la categoría de ahorro: se guarda así en la BD sin
/// importar el idioma de la interfaz.
const kSavingsCategory = 'Ahorro';

class Transaction {
  final int? id;
  final String description;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String category;
  final bool isRecurring;
  final RecurringType recurringType;
  final int recurringIntervalDays;
  final String? recurringGroupId;

  const Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.category = 'General',
    this.isRecurring = false,
    this.recurringType = RecurringType.monthly,
    this.recurringIntervalDays = 7,
    this.recurringGroupId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'description': description,
    'amount': amount,
    'is_income': isIncome ? 1 : 0,
    'date': date.toIso8601String(),
    'category': category,
    'is_recurring': isRecurring ? 1 : 0,
    'recurring_type': recurringType.name,
    'recurring_interval': recurringIntervalDays,
    'recurring_group_id': recurringGroupId,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'] as int?,
    description: map['description'] as String,
    amount: (map['amount'] as num).toDouble(),
    isIncome: map['is_income'] == 1,
    date: DateTime.parse(map['date'] as String),
    category: map['category'] as String? ?? 'General',
    isRecurring: map['is_recurring'] == 1,
    recurringType: _parseType(map['recurring_type'] as String?),
    recurringIntervalDays: (map['recurring_interval'] as int?) ?? 7,
    recurringGroupId: map['recurring_group_id'] as String?,
  );

  static RecurringType _parseType(String? value) => RecurringType.values
      .firstWhere((e) => e.name == value, orElse: () => RecurringType.monthly);

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    bool? isIncome,
    DateTime? date,
    String? category,
    bool? isRecurring,
    RecurringType? recurringType,
    int? recurringIntervalDays,
    String? recurringGroupId,
  }) => Transaction(
    id: id ?? this.id,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    isIncome: isIncome ?? this.isIncome,
    date: date ?? this.date,
    category: category ?? this.category,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringType: recurringType ?? this.recurringType,
    recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
    recurringGroupId: recurringGroupId ?? this.recurringGroupId,
  );
}
