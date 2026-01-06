import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Still needed for logic

// MODELS
import '../models/finance_models.dart';

// WIDGETS
import '../widgets/finance/add_transaction_dialog.dart';
import '../widgets/finance/past_month_summary.dart';
import '../widgets/finance/finance_dashboard.dart';
import '../widgets/finance/edit_monthly_budget_dialog.dart';
import '../widgets/finance/finance_header.dart'; // NEW IMPORT

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isInspectingPast = false;
  bool _showChart = false;

  // --- HARDCODED BUCKETS (Will move to Firestore later) ---
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

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month;
  }

  bool get _isFutureMonth {
    final now = DateTime.now();
    if (_selectedDate.year > now.year) return true;
    if (_selectedDate.year == now.year && _selectedDate.month > now.month)
      return true;
    return false;
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        1,
      );
      _isInspectingPast = false;
    });
  }

  // --- SHOW ALL BUDGETS DIALOG ---
  void _showEditMonthlyBudgets() {
    showDialog(
      context: context,
      builder: (ctx) => EditMonthlyBudgetDialog(
        buckets: _baseBuckets,
        onUpdateLimit: _updateBucketLimit,
      ),
    );
  }

  // --- UPDATE SINGLE BUCKET LIMIT ---
  void _updateBucketLimit(
    String bucketId,
    double currentLimit,
    String name, [
    VoidCallback? onSaved,
  ]) {
    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Budget: $name",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: "Monthly Limit (\$)",
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade700),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newLimit =
                            double.tryParse(controller.text) ?? currentLimit;
                        setState(() {
                          final index = _baseBuckets.indexWhere(
                            (b) => b.id == bucketId,
                          );
                          if (index != -1) {
                            _baseBuckets[index] = _baseBuckets[index].copyWith(
                              limit: newLimit,
                            );
                          }
                        });
                        if (onSaved != null) onSaved();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  List<FinanceTransaction> _mapSnapshotToTransactions(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FinanceTransaction(
        id: doc.id,
        title: data['title'] ?? 'Unknown',
        amount: (data['amount'] ?? 0.0).toDouble(),
        date: (data['date'] as Timestamp).toDate(),
        categoryId: data['categoryId'] ?? 'others',
        isExpense: data['isExpense'] ?? true,
        iconCode: data['iconCode'],
        colorValue: data['colorValue'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isCurrentMonth
          ? FloatingActionButton(
              onPressed: _onAddTransaction,
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('finance_transactions')
            .where('userId', isEqualTo: 'test_user')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allTransactions = _mapSnapshotToTransactions(snapshot.data!);

          final monthTransactions = allTransactions.where((t) {
            return t.date.year == _selectedDate.year &&
                t.date.month == _selectedDate.month;
          }).toList();

          final monthlyExpense = monthTransactions
              .where((t) => t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final monthlyIncome = monthTransactions
              .where((t) => !t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final calculatedBuckets = _baseBuckets.map((bucket) {
            final bucketSpent = monthTransactions
                .where((t) => t.isExpense && t.categoryId == bucket.id)
                .fold(0.0, (sum, t) => sum + t.amount);
            return bucket.copyWith(spent: bucketSpent);
          }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- NEW HEADER WIDGET ---
                FinanceHeader(
                  selectedDate: _selectedDate,
                  onMonthChanged: _changeMonth,
                  isInspectingPast: _isInspectingPast,
                  showChart: _showChart,
                  onChartToggle: (val) => setState(() => _showChart = val),
                  onResetDate: () => setState(() {
                    _selectedDate = DateTime.now();
                    _isInspectingPast = false;
                  }),
                ),

                if (!_isCurrentMonth && !_isFutureMonth && !_isInspectingPast)
                  PastMonthSummary(
                    selectedDate: _selectedDate,
                    income: monthlyIncome,
                    expense: monthlyExpense,
                    isDark: isDark,
                    onBackToToday: () =>
                        setState(() => _selectedDate = DateTime.now()),
                    onInspect: () => setState(() => _isInspectingPast = true),
                  )
                else
                  FinanceDashboard(
                    isDark: isDark,
                    showChart: _showChart,
                    transactions: monthTransactions,
                    buckets: calculatedBuckets,
                    monthlyIncome: monthlyIncome,
                    monthlyExpense: monthlyExpense,
                    onEditTransaction: _onEditTransaction,
                    onUpdateBucketLimit: _updateBucketLimit,
                    onEditAllBudgets: _showEditMonthlyBudgets,
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
