import '../models/transaction.dart';

const _monthsFullEs = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _monthsFullEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthsShortEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];
const _monthsShortEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _daysShortEs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _daysShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _daysFullEs = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const _daysFullEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Las categorías se guardan en la BD con su nombre en español (canónico);
/// aquí solo se traduce cómo se muestran.
const _categoryLabelsEn = {
  'Salario': 'Salary',
  'Freelance': 'Freelance',
  'Inversión': 'Investment',
  'Bono': 'Bonus',
  'Otro': 'Other',
  'Ahorro': 'Savings',
  'Comida': 'Food',
  'Transporte': 'Transport',
  'Vivienda': 'Housing',
  'Entretenimiento': 'Entertainment',
  'Salud': 'Health',
  'Compras': 'Shopping',
  'Educación': 'Education',
  'Servicios': 'Utilities',
  'General': 'General',
};

class Strings {
  final bool isEn;
  const Strings(this.isEn);

  static const es = Strings(false);
  static const en = Strings(true);

  List<String> get monthsFull => isEn ? _monthsFullEn : _monthsFullEs;
  List<String> get monthsShort => isEn ? _monthsShortEn : _monthsShortEs;
  List<String> get daysShort => isEn ? _daysShortEn : _daysShortEs;
  List<String> get daysFull => isEn ? _daysFullEn : _daysFullEs;

  String categoryLabel(String category) =>
      isEn ? (_categoryLabelsEn[category] ?? category) : category;

  /// «12 de Junio 2026» / «June 12, 2026»
  String longDate(DateTime d) => isEn
      ? '${monthsFull[d.month - 1]} ${d.day}, ${d.year}'
      : '${d.day} de ${monthsFull[d.month - 1]} ${d.year}';

  // ── Dashboard ──
  String get monthly => isEn ? 'Monthly' : 'Mensual';
  String get weekly => isEn ? 'Weekly' : 'Semanal';
  String get balance => isEn ? 'Balance' : 'Balance';
  String get annual => isEn ? 'Yearly' : 'Anual';
  String get income => isEn ? 'Income' : 'Ingresos';
  String get expenses => isEn ? 'Expenses' : 'Gastos';
  String get savings => isEn ? 'Savings' : 'Ahorro';
  String get incomeSingular => isEn ? 'Income' : 'Ingreso';
  String get expenseSingular => isEn ? 'Expense' : 'Egreso';
  String get expensesPlural => isEn ? 'Expenses' : 'Egresos';
  String get noData => isEn ? 'No data' : 'Sin datos';
  String get add => isEn ? 'Add' : 'Agregar';
  String get today => isEn ? 'TODAY' : 'HOY';
  String weekRangeSameMonth(int startDay, int endDay, String month) => isEn
      ? '$month $startDay — $endDay'
      : '$startDay — $endDay de $month';

  // ── Day / month detail ──
  String get noMovements => isEn ? 'No movements' : 'Sin movimientos';
  String get noIncomeRegistered =>
      isEn ? 'No income registered' : 'No hay ingresos registrados';
  String get noExpensesRegistered =>
      isEn ? 'No expenses registered' : 'No hay gastos registrados';
  String get deleteAllTooltip => isEn ? 'Delete all' : 'Eliminar todos';
  String get cancelSelection =>
      isEn ? 'Cancel selection' : 'Cancelar selección';
  String get selectAll => isEn ? 'Select all' : 'Seleccionar todos';
  String get deselectAll => isEn ? 'Deselect all' : 'Deseleccionar todos';
  String get deleteSelected =>
      isEn ? 'Delete selected' : 'Eliminar seleccionados';
  String selectedCount(int n) => isEn
      ? '$n selected'
      : '$n ${n == 1 ? 'seleccionado' : 'seleccionados'}';
  String get deleteMovementsTitle =>
      isEn ? 'Delete movements?' : '¿Eliminar movimientos?';
  String deleteMovementsBody(int n) => isEn
      ? '$n ${n == 1 ? 'movement' : 'movements'} will be deleted. This action cannot be undone.'
      : 'Se ${n == 1 ? 'eliminará 1 movimiento' : 'eliminarán $n movimientos'}. Esta acción no se puede deshacer.';
  String get cancel => isEn ? 'Cancel' : 'Cancelar';
  String get delete => isEn ? 'Delete' : 'Eliminar';
  String get saldo => isEn ? 'Balance' : 'Saldo';
  String get noTransactions => isEn ? 'No transactions' : 'Sin transacciones';
  String get addForMonthHint => isEn
      ? 'Add income or expenses for this month'
      : 'Agrega ingresos o gastos para este mes';
  String get addTransaction =>
      isEn ? 'Add transaction' : 'Agregar transacción';

  // ── Month type detail ──
  String get total => isEn ? 'Total' : 'Total';
  String movementsInMonth(int n, String month) => isEn
      ? '$n ${n == 1 ? 'movement' : 'movements'} in $month'
      : '$n ${n == 1 ? 'movimiento' : 'movimientos'} en $month';
  String get tapForDetail =>
      isEn ? 'Tap to see the detail' : 'Toca para ver el detalle';
  String nMovements(int n) =>
      isEn ? '$n movements' : '$n movimientos';
  String noTypeThisMonth(String type) => isEn
      ? 'No ${type.toLowerCase()} registered this month'
      : 'No hay ${type.toLowerCase()} registrados este mes';

  // ── Recurring ──
  String get recurring => isEn ? 'Recurring' : 'Recurrentes';
  String get noRecurring =>
      isEn ? 'No recurring movements' : 'Sin movimientos recurrentes';
  String get recurringHint => isEn
      ? 'Movements with repetition will appear here'
      : 'Los movimientos con repetición aparecerán aquí';
  String frequencyLabel(Transaction t) {
    switch (t.recurringType) {
      case RecurringType.daily:
        return isEn ? 'Daily' : 'Diario';
      case RecurringType.weekly:
        return isEn ? 'Weekly' : 'Semanal';
      case RecurringType.monthly:
        return isEn ? 'Monthly' : 'Mensual';
      case RecurringType.custom:
        return isEn
            ? 'Every ${t.recurringIntervalDays} days'
            : 'Cada ${t.recurringIntervalDays} días';
    }
  }
  String timesCount(int n) =>
      isEn ? '$n ${n == 1 ? 'time' : 'times'}' : '$n ${n == 1 ? 'vez' : 'veces'}';
  String get deleteSeriesTitle =>
      isEn ? 'Delete recurring series?' : '¿Eliminar serie recurrente?';
  String deleteSeriesBody(String desc, int n) => isEn
      ? '"$desc" and its $n ${n == 1 ? 'movement' : 'movements'} will be deleted. This action cannot be undone.'
      : 'Se eliminará "$desc" con sus $n ${n == 1 ? 'movimiento' : 'movimientos'}. Esta acción no se puede deshacer.';
  String get deleteEverything => isEn ? 'Delete all' : 'Eliminar todo';

  // ── Settings ──
  String get settings => isEn ? 'Settings' : 'Configuración';
  String get language => isEn ? 'Language' : 'Idioma';
  String get spanish => isEn ? 'Spanish' : 'Español';
  String get english => isEn ? 'English' : 'Inglés';
  String get theme => isEn ? 'Theme' : 'Tema';
  String get darkMode => isEn ? 'Dark' : 'Oscuro';
  String get lightMode => isEn ? 'Light' : 'Claro';
  String get currency => isEn ? 'Currency' : 'Moneda';

  // ── Profile ──
  String get myProfile => isEn ? 'My profile' : 'Mi perfil';
  String get aliasLabel => isEn ? 'Alias' : 'Alias';
  String get aliasHint =>
      isEn ? 'How do you want to be called?' : '¿Cómo quieres que te llamemos?';
  String get save => isEn ? 'Save' : 'Guardar';
  String get aliasSaved => isEn ? 'Alias saved' : 'Alias guardado';

  // ── Add transaction sheet ──
  String get editTransaction =>
      isEn ? 'Edit Transaction' : 'Editar Transacción';
  String get newTransaction =>
      isEn ? 'Add Transaction' : 'Agregar Transacción';
  String get expenseToggle => isEn ? 'Expense' : 'Gasto';
  String get incomeToggle => isEn ? 'Income' : 'Ingreso';
  String get description => isEn ? 'Description' : 'Descripción';
  String get amount => isEn ? 'Amount' : 'Monto';
  String get category => isEn ? 'Category' : 'Categoría';
  String get recurrente => isEn ? 'Recurring' : 'Recurrente';
  String get custom => isEn ? 'Custom' : 'Personalizado';
  String get every => isEn ? 'Every' : 'Cada';
  String get days => isEn ? 'days' : 'días';
  String get update => isEn ? 'Update' : 'Actualizar';
  String get deleteTransaction =>
      isEn ? 'Delete transaction' : 'Eliminar transacción';
  String get deleteTransactionConfirm => isEn
      ? 'Are you sure you want to delete this transaction?'
      : '¿Estás seguro de que quieres eliminar esta transacción?';
  String get fillAllFields => isEn
      ? 'Fill in all fields correctly'
      : 'Completa todos los campos correctamente';
}
