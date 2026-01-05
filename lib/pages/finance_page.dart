import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/finance/bucket_list.dart';
import '../widgets/finance/transaction_list.dart';
import '../widgets/finance/pie_chart_view.dart';
import '../widgets/finance/add_transaction_dialog.dart';
import '../widgets/finance/budget_progress_bar.dart';

// --- MOCK MODELS ---
class MockBucket {
  final String id;
  final String name;
  final double limit;
  final double spent;
  final IconData icon;
  final Color color;
  final bool isFixed;

  MockBucket(
    this.id,
    this.name,
    this.limit,
    this.spent,
    this.icon,
    this.color, {
    this.isFixed = false,
  });

  MockBucket copyWith({double? limit, double? spent}) {
    return MockBucket(
      id,
      name,
      limit ?? this.limit,
      spent ?? this.spent,
      icon,
      color,
      isFixed: isFixed,
    );
  }
}

class MockTransaction {
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final bool isExpense;
  final IconData? icon;
  final Color? color;

  MockTransaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.isExpense = true,
    this.icon,
    this.color,
  });
}

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

  // NEW: Track if we are "Inspecting" a past month details
  bool _isInspectingPast = false;

  // --- DATA ---
  List<MockBucket> _baseBuckets = [
    MockBucket(
      '2',
      'Rent',
      800.0,
      0,
      Icons.home_rounded,
      Colors.blue,
      isFixed: true,
    ),
    MockBucket(
      '5',
      'Subscriptions',
      60.0,
      0,
      Icons.subscriptions_rounded,
      Colors.teal,
      isFixed: true,
    ),
    MockBucket(
      '1',
      'Dining',
      150.0,
      0,
      Icons.restaurant_rounded,
      Colors.orange,
    ),
    MockBucket(
      '6',
      'Groceries',
      200.0,
      0,
      Icons.shopping_cart_rounded,
      Colors.green,
    ),
    MockBucket(
      '4',
      'Transport',
      100.0,
      0,
      Icons.directions_bus_rounded,
      Colors.indigo,
    ),
    MockBucket('3', 'Fun', 100.0, 0, Icons.movie_rounded, Colors.purple),
  ];

  late List<MockBucket> _calculatedBuckets;
  List<MockTransaction> _monthTransactions = [];

  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  final List<MockTransaction> _allTransactions = [
    // Current Month
    MockTransaction(
      title: 'Rent Payment',
      amount: 800.00,
      date: DateTime.now(),
      categoryId: '2',
    ),
    MockTransaction(
      title: 'Grocery Run',
      amount: 45.00,
      date: DateTime.now(),
      categoryId: '6',
    ),
    MockTransaction(
      title: 'Burger King',
      amount: 12.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
      categoryId: '1',
    ),
    MockTransaction(
      title: 'Bus Pass',
      amount: 20.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      categoryId: '4',
    ),

    // Past Month (Mock Data for Testing)
    MockTransaction(
      title: 'Last Month Rent',
      amount: 800.00,
      date: DateTime.now().subtract(const Duration(days: 35)),
      categoryId: '2',
    ),
    MockTransaction(
      title: 'Holiday Travel',
      amount: 150.00,
      date: DateTime.now().subtract(const Duration(days: 32)),
      categoryId: '4',
    ),
    MockTransaction(
      title: 'Christmas Gift',
      amount: 200.00,
      date: DateTime.now().subtract(const Duration(days: 31)),
      categoryId: '3',
    ),
    MockTransaction(
      title: 'Bonus',
      amount: 500.00,
      date: DateTime.now().subtract(const Duration(days: 33)),
      categoryId: 'income',
      isExpense: false,
      icon: Icons.card_giftcard,
      color: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _recalculateData();
  }

  // Check if we are viewing the current actual month
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
      _isInspectingPast = false; // Reset inspection when changing months
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

  void _editBucketLimit(String bucketId) {
    final bucket = _baseBuckets.firstWhere((b) => b.id == bucketId);
    final controller = TextEditingController(
      text: bucket.limit.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Budget: ${bucket.name}"),
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
              final newLimit = double.tryParse(controller.text) ?? bucket.limit;
              setState(() {
                final index = _baseBuckets.indexWhere((b) => b.id == bucketId);
                if (index != -1) {
                  _baseBuckets[index] = _baseBuckets[index].copyWith(
                    limit: newLimit,
                  );
                }
                _recalculateData();
              });
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showGlobalBudgetEditor() {
    // ... [Same implementation as before] ...
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Edit Monthly Budget",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _baseBuckets.length,
                  itemBuilder: (context, index) {
                    final bucket = _baseBuckets[index];
                    return ListTile(
                      leading: Icon(bucket.icon, color: bucket.color),
                      title: Text(bucket.name),
                      trailing: SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: bucket.limit.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: "\$ "),
                          onChanged: (val) {
                            final newLimit =
                                double.tryParse(val) ?? bucket.limit;
                            _baseBuckets[index] = bucket.copyWith(
                              limit: newLimit,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _recalculateData());
                  Navigator.pop(ctx);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAddTransaction() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        buckets: _baseBuckets,
        onAdd: (newTx) {
          setState(() {
            _allTransactions.insert(
              0,
              MockTransaction(
                title: newTx['title'],
                amount: newTx['amount'],
                date: newTx['date'],
                categoryId: newTx['bucketId'] ?? 'income',
                isExpense: newTx['isExpense'],
                icon: newTx['categoryIcon'],
                color: newTx['categoryColor'],
              ),
            );
            if (newTx['date'].month == _selectedDate.month) {
              _recalculateData();
            }
          });
        },
      ),
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
      // HIDE ADD BUTTON IF VIEWING PAST MONTH
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
            // 1. MONTH HEADER
            Padding(
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
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
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
            ),

            // CONDITIONAL VIEW: PAST SUMMARY vs ACTIVE DASHBOARD
            if (!_isCurrentMonth && !_isInspectingPast)
              _buildPastMonthSummary(isDark, textColor, primaryColor)
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

  // --- VIEW 1: PAST MONTH SUMMARY CARD ---
  Widget _buildPastMonthSummary(
    bool isDark,
    Color textColor,
    Color primaryColor,
  ) {
    final netSavings = _monthlyIncome - _monthlyExpense;
    final isPositive = netSavings >= 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Big Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                    : [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isPositive ? Icons.savings_rounded : Icons.warning_rounded,
                  size: 48,
                  color: isPositive ? Colors.green : Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  isPositive ? "Great Job!" : "Over Budget",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPositive
                      ? "You saved \$${netSavings.toStringAsFixed(0)} in ${DateFormat('MMMM').format(_selectedDate)}."
                      : "You spent \$${netSavings.abs().toStringAsFixed(0)} more than you earned.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Income", _monthlyIncome, Colors.green),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    _buildStatItem(
                      "Expense",
                      _monthlyExpense,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _recalculateData();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Text(
                    "Back to Today",
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isInspectingPast = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Inspect Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          "\$${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: ACTIVE DASHBOARD (Buckets, List, etc.) ---
  Widget _buildMainDashboard(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
  ) {
    // [Logic for Filter/Charts from before]
    List<MockTransaction> displayedTransactions = _monthTransactions;
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

    final double chartTotal = _calculatedBuckets.fold(
      0,
      (sum, item) => sum + item.spent,
    );
    final List<ChartData> chartData = _calculatedBuckets.map((b) {
      return ChartData(b.id, b.name, b.spent, b.color, b.icon);
    }).toList();

    final double totalBudgetLimit = _calculatedBuckets.fold(
      0.0,
      (sum, b) => sum + b.limit,
    );
    final double totalBudgetSpent = _calculatedBuckets.fold(
      0.0,
      (sum, b) => sum + b.spent,
    );

    // Smart Pacing Math
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

    MockBucket? selectedBucket;
    if (_selectedBucketId != null) {
      selectedBucket = _calculatedBuckets.firstWhere(
        (b) => b.id == _selectedBucketId,
      );
    }

    return Column(
      children: [
        // SUMMARY ROW
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

        // GLOBAL BUDGET BAR
        if (!_showChart)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: GestureDetector(
              onTap: _showGlobalBudgetEditor,
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
          ),

        // MAIN CONTENT
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

        // HISTORY HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (selectedBucket != null)
                    Row(
                      children: [
                        Icon(
                          selectedBucket.icon,
                          color: selectedBucket.color,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedBucket.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      "History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                  if (_selectedBucketId != null)
                    Row(
                      children: [
                        ActionChip(
                          // LOGIC FIX: Check if limit exists
                          label: Text(
                            selectedBucket!.limit > 0
                                ? "Edit Limit"
                                : "Set Goal",
                          ),
                          avatar: Icon(
                            selectedBucket.limit > 0 ? Icons.edit : Icons.flag,
                            size: 14,
                          ),
                          onPressed: () => _editBucketLimit(_selectedBucketId!),
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.white,
                          side: BorderSide.none,
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text("Close"),
                          avatar: const Icon(Icons.close, size: 14),
                          onPressed: () =>
                              setState(() => _selectedBucketId = null),
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.white,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                ],
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
