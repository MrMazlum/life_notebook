import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// MODELS
import '../models/finance_models.dart';

// WIDGETS
import '../widgets/finance/bucket_list.dart';
import '../widgets/finance/transaction_list.dart';
import '../widgets/finance/pie_chart_view.dart';
import '../widgets/finance/add_transaction_dialog.dart';
import '../widgets/finance/budget_progress_bar.dart';
import '../widgets/finance/past_month_summary.dart';

enum FilterType { all, income, expense }

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  String? _selectedBucketId;
  bool _showChart = false;
  DateTime _selectedDate = DateTime.now();
  FilterType _currentFilter = FilterType.all;
  bool _isInspectingPast = false;

  // --- TEMPORARY DATA FOR UI VERIFICATION ---
  List<FinanceBucket> _baseBuckets = [
    FinanceBucket(
      id: '2',
      name: 'Rent',
      limit: 800.0,
      spent: 0,
      iconCode: Icons.home_rounded.codePoint,
      colorValue: Colors.blue.value,
      isFixed: true,
    ),
    FinanceBucket(
      id: '5',
      name: 'Subscriptions',
      limit: 60.0,
      spent: 0,
      iconCode: Icons.subscriptions_rounded.codePoint,
      colorValue: Colors.teal.value,
      isFixed: true,
    ),
    FinanceBucket(
      id: '1',
      name: 'Dining',
      limit: 150.0,
      spent: 0,
      iconCode: Icons.restaurant_rounded.codePoint,
      colorValue: Colors.orange.value,
    ),
    FinanceBucket(
      id: '6',
      name: 'Groceries',
      limit: 200.0,
      spent: 0,
      iconCode: Icons.shopping_cart_rounded.codePoint,
      colorValue: Colors.green.value,
    ),
    FinanceBucket(
      id: '4',
      name: 'Transport',
      limit: 100.0,
      spent: 0,
      iconCode: Icons.directions_bus_rounded.codePoint,
      colorValue: Colors.indigo.value,
    ),
    FinanceBucket(
      id: '3',
      name: 'Fun',
      limit: 100.0,
      spent: 0,
      iconCode: Icons.movie_rounded.codePoint,
      colorValue: Colors.purple.value,
    ),
  ];

  late List<FinanceBucket> _calculatedBuckets;
  List<FinanceTransaction> _monthTransactions = [];

  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  final List<FinanceTransaction> _allTransactions = [
    FinanceTransaction(
      id: 't1',
      title: 'Rent Payment',
      amount: 800.00,
      date: DateTime.now(),
      categoryId: '2',
      isExpense: true,
    ),
    FinanceTransaction(
      id: 't2',
      title: 'Grocery Run',
      amount: 45.00,
      date: DateTime.now(),
      categoryId: '6',
      isExpense: true,
    ),
    FinanceTransaction(
      id: 't3',
      title: 'Burger King',
      amount: 12.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
      categoryId: '1',
      isExpense: true,
    ),
    FinanceTransaction(
      id: 't4',
      title: 'Bonus',
      amount: 500.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      categoryId: 'income',
      isExpense: false,
      iconCode: Icons.card_giftcard.codePoint,
      colorValue: Colors.amber.value,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _recalculateData();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month;
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        1,
      );
      _isInspectingPast = false;
      _recalculateData();
    });
  }

  void _recalculateData() {
    _monthTransactions = _allTransactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
    }).toList();

    _monthlyExpense = _monthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    _monthlyIncome = _monthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    _calculatedBuckets = _baseBuckets.map((bucket) {
      final bucketSpent = _monthTransactions
          .where((t) => t.isExpense && t.categoryId == bucket.id)
          .fold(0.0, (sum, t) => sum + t.amount);
      return bucket.copyWith(spent: bucketSpent);
    }).toList();
  }

  void _toggleFilter(FilterType type) {
    setState(() {
      if (_currentFilter == type) {
        _currentFilter = FilterType.all;
      } else {
        _currentFilter = type;
        _selectedBucketId = null;
      }
    });
  }

  // UPDATED: Updates Local List so you can see it work instantly
  void _updateBucketLimit(String bucketId, double currentLimit, String name) {
    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Budget: $name"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Monthly Limit (\$)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? currentLimit;
              // Update Locally for Verification
              setState(() {
                final index = _baseBuckets.indexWhere((b) => b.id == bucketId);
                if (index != -1) {
                  _baseBuckets[index] = _baseBuckets[index].copyWith(
                    limit: newLimit,
                  );
                  _recalculateData();
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _onEditTransaction(FinanceTransaction tx) {
    showDialog(
      context: context,
      builder: (context) =>
          AddTransactionDialog(buckets: _baseBuckets, transactionToEdit: tx),
    );
  }

  void _onAddTransaction() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(buckets: _baseBuckets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isCurrentMonth
          ? FloatingActionButton(
              onPressed: _onAddTransaction,
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(subTextColor, textColor),
            if (!_isCurrentMonth && !_isInspectingPast)
              PastMonthSummary(
                selectedDate: _selectedDate,
                income: _monthlyIncome,
                expense: _monthlyExpense,
                isDark: isDark,
                onBackToToday: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _recalculateData();
                  });
                },
                onInspect: () => setState(() => _isInspectingPast = true),
              )
            else
              _buildMainDashboard(
                isDark,
                textColor,
                subTextColor,
                primaryColor,
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(Color subTextColor, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: () => _changeMonth(-1),
                color: subTextColor,
              ),
              Column(
                children: [
                  Text(
                    "Budget",
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                onPressed: () => _changeMonth(1),
                color: subTextColor,
              ),
            ],
          ),
          if (_isCurrentMonth || _isInspectingPast)
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleBtn(
                    Icons.pie_chart_rounded,
                    true,
                    isDark,
                    primaryColor,
                  ),
                  _buildToggleBtn(
                    Icons.view_list_rounded,
                    false,
                    isDark,
                    primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
  ) {
    // Filter Logic
    List<FinanceTransaction> displayedTransactions = _monthTransactions;
    if (_currentFilter == FilterType.expense) {
      displayedTransactions = displayedTransactions
          .where((t) => t.isExpense)
          .toList();
    } else if (_currentFilter == FilterType.income) {
      displayedTransactions = displayedTransactions
          .where((t) => !t.isExpense)
          .toList();
    }
    if (_selectedBucketId != null) {
      displayedTransactions = displayedTransactions
          .where((t) => t.categoryId == _selectedBucketId)
          .toList();
    }

    final chartTotal = _calculatedBuckets.fold(
      0.0,
      (sum, item) => sum + item.spent,
    );
    final chartData = _calculatedBuckets
        .map((b) => ChartData(b.id, b.name, b.spent, b.color, b.icon))
        .toList();
    final totalBudgetLimit = _calculatedBuckets.fold(
      0.0,
      (sum, b) => sum + b.limit,
    );
    final totalBudgetSpent = _calculatedBuckets.fold(
      0.0,
      (sum, b) => sum + b.spent,
    );

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final timeProgress = (now.day / daysInMonth).clamp(0.0, 1.0);
    double totalIdealSpent = 0.0;
    for (var b in _calculatedBuckets) {
      if (b.isFixed) {
        totalIdealSpent += b.limit;
      } else {
        totalIdealSpent += b.limit * timeProgress;
      }
    }

    FinanceBucket? selectedBucket;
    if (_selectedBucketId != null) {
      try {
        selectedBucket = _calculatedBuckets.firstWhere(
          (b) => b.id == _selectedBucketId,
        );
      } catch (_) {}
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  _monthlyIncome,
                  Colors.green,
                  isDark,
                  FilterType.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Expense",
                  _monthlyExpense,
                  Colors.redAccent,
                  isDark,
                  FilterType.expense,
                ),
              ),
            ],
          ),
        ),
        if (!_showChart)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Monthly Budget",
                      style: TextStyle(fontSize: 12, color: subTextColor),
                    ),
                    Icon(Icons.edit, size: 12, color: subTextColor),
                  ],
                ),
                const SizedBox(height: 8),
                BudgetProgressBar(
                  spent: totalBudgetSpent,
                  limit: totalBudgetLimit,
                  color: primaryColor,
                  isFixed: false,
                  customIdeal: totalIdealSpent,
                ),
              ],
            ),
          ),
        SizedBox(
          height: _showChart ? 320 : 210,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showChart
                ? PieChartView(
                    key: const ValueKey('chart'),
                    totalSpent: chartTotal,
                    data: chartData,
                    onSectionTap: (id) => setState(() {
                      _selectedBucketId = _selectedBucketId == id ? null : id;
                      _currentFilter = FilterType.all;
                    }),
                  )
                : BucketList(
                    key: const ValueKey('list'),
                    buckets: _calculatedBuckets,
                    selectedBucketId: _selectedBucketId,
                    onBucketSelected: (id) => setState(() {
                      _selectedBucketId = id;
                      _currentFilter = FilterType.all;
                    }),
                  ),
          ),
        ),
        const SizedBox(height: 10),

        // --- HISTORY HEADER (FIXED: CENTERED TITLE, BACK BUTTON) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // LEFT: Selected Bucket
                    if (selectedBucket != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedBucket.icon,
                              color: selectedBucket.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedBucket.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // CENTER: History Title
                    if (selectedBucket == null)
                      Text(
                        "History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                    // RIGHT: Actions
                    if (selectedBucket != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Limit (Sleek Pill)
                            InkWell(
                              onTap: () => _updateBucketLimit(
                                selectedBucket!.id,
                                selectedBucket.limit,
                                selectedBucket.name,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Limit",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // BACK BUTTON (RENAMED FROM CLEAR)
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectedBucketId = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 12,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (selectedBucket != null) ...[
                const SizedBox(height: 12),
                BudgetProgressBar(
                  spent: selectedBucket.spent,
                  limit: selectedBucket.limit,
                  color: selectedBucket.color,
                  isFixed: selectedBucket.isFixed,
                  showLabels: true,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // TRANSACTION LIST
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TransactionList(
            transactions: displayedTransactions,
            buckets: _calculatedBuckets,
            isDark: isDark,
            onEdit: _onEditTransaction,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    bool isDark,
    FilterType type,
  ) {
    bool isSelected = _currentFilter == type;
    Color bg = isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1);
    Color border = isSelected ? color : Colors.transparent;

    return GestureDetector(
      onTap: () => _toggleFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isSelected) Icon(Icons.check, size: 12, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "\$${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(
    IconData icon,
    bool isChart,
    bool isDark,
    Color activeColor,
  ) {
    final isSelected = _showChart == isChart;
    return GestureDetector(
      onTap: () => setState(() => _showChart = isChart),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white54 : Colors.black54),
        ),
      ),
    );
  }
}
