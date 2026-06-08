class Transaction {
  final int? id;
  final String description;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String category;
  final bool isRecurring;

  const Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.category = 'General',
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'description': description,
    'amount': amount,
    'is_income': isIncome ? 1 : 0,
    'date': date.toIso8601String(),
    'category': category,
    'is_recurring': isRecurring ? 1 : 0,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'] as int?,
    description: map['description'] as String,
    amount: (map['amount'] as num).toDouble(),
    isIncome: map['is_income'] == 1,
    date: DateTime.parse(map['date'] as String),
    category: map['category'] as String? ?? 'General',
    isRecurring: map['is_recurring'] == 1,
  );

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    bool? isIncome,
    DateTime? date,
    String? category,
    bool? isRecurring,
  }) => Transaction(
    id: id ?? this.id,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    isIncome: isIncome ?? this.isIncome,
    date: date ?? this.date,
    category: category ?? this.category,
    isRecurring: isRecurring ?? this.isRecurring,
  );
}
