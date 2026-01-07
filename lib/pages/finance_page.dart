import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- IMPORT ADDED

// MODELS
import '../models/finance_models.dart';

// WIDGETS
import '../widgets/finance/add_transaction_dialog.dart';
import '../widgets/finance/past_month_summary.dart';
import '../widgets/finance/finance_dashboard.dart';
import '../widgets/finance/edit_monthly_budget_dialog.dart';
import '../widgets/finance/finance_header.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isInspectingPast = false;
  bool _showChart = false;

  final CollectionReference _bucketsRef = FirebaseFirestore.instance.collection(
    'finance_buckets',
  );
  final CollectionReference _txRef = FirebaseFirestore.instance.collection(
    'finance_transactions',
  );

  // --- INITIALIZATION ---
  @override
  void initState() {
    super.initState();
    _ensureBucketsExist();
  }

  // Create default buckets if user has none
  Future<void> _ensureBucketsExist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Wait for login

    // Check buckets for REAL user ID
    final snapshot = await _bucketsRef
        .where('userId', isEqualTo: user.uid) // <--- CHECK REAL ID
        .get();

    if (snapshot.docs.isEmpty) {
      final defaults = [
        FinanceBucket(
          id: '',
          name: 'Rent',
          limit: 800,
          iconCode: Icons.home_rounded.codePoint,
          colorValue: Colors.blue.value,
          isFixed: true,
        ),
        FinanceBucket(
          id: '',
          name: 'Groceries',
          limit: 200,
          iconCode: Icons.shopping_cart_rounded.codePoint,
          colorValue: Colors.green.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Dining',
          limit: 150,
          iconCode: Icons.restaurant_rounded.codePoint,
          colorValue: Colors.orange.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Transport',
          limit: 100,
          iconCode: Icons.directions_bus_rounded.codePoint,
          colorValue: Colors.indigo.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Fun',
          limit: 100,
          iconCode: Icons.movie_rounded.codePoint,
          colorValue: Colors.purple.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Subscriptions',
          limit: 60,
          iconCode: Icons.subscriptions_rounded.codePoint,
          colorValue: Colors.teal.value,
          isFixed: true,
        ),
      ];

      for (var b in defaults) {
        // Add userId to the bucket map so it belongs to this user
        final bucketMap = b.toMap();
        bucketMap['userId'] = user.uid; // <--- IMPORTANT: LINK BUCKET TO USER
        await _bucketsRef.add(bucketMap);
      }
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month;
  }

  bool get _isFutureMonth {
    final now = DateTime.now();
    if (_selectedDate.year > now.year) return true;
    if (_selectedDate.year == now.year && _selectedDate.month > now.month) {
      return true;
    }
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

  // --- UPDATE LIMIT ---
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
                  hintText: "e.g. 500",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newLimit =
                            double.tryParse(controller.text) ?? currentLimit;
                        _bucketsRef.doc(bucketId).update({'limit': newLimit});
                        if (onSaved != null) onSaved();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  void _showEditMonthlyBudgets(List<FinanceBucket> currentBuckets) {
    showDialog(
      context: context,
      builder: (ctx) => EditMonthlyBudgetDialog(
        buckets: currentBuckets,
        onUpdateLimit: _updateBucketLimit,
      ),
    );
  }

  void _onEditTransaction(FinanceTransaction tx, List<FinanceBucket> buckets) {
    showDialog(
      context: context,
      builder: (context) =>
          AddTransactionDialog(buckets: buckets, transactionToEdit: tx),
    );
  }

  void _onAddTransaction(List<FinanceBucket> buckets) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(buckets: buckets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // GET CURRENT USER
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. STREAM BUCKETS
    return StreamBuilder<QuerySnapshot>(
      stream: _bucketsRef
          .where('userId', isEqualTo: user.uid)
          .snapshots(), // <--- REAL ID
      builder: (context, bucketSnap) {
        if (!bucketSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final buckets = bucketSnap.data!.docs
            .map((doc) => FinanceBucket.fromFirestore(doc))
            .toList();

        // 2. STREAM TRANSACTIONS
        return StreamBuilder<QuerySnapshot>(
          stream: _txRef
              .where('userId', isEqualTo: user.uid) // <--- REAL ID
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, txSnap) {
            if (!txSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTransactions = txSnap.data!.docs
                .map((doc) => FinanceTransaction.fromFirestore(doc))
                .toList();

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

            // Calculate 'spent' for each bucket dynamically
            final calculatedBuckets = buckets.map((bucket) {
              final bucketSpent = monthTransactions
                  .where((t) => t.isExpense && t.categoryId == bucket.id)
                  .fold(0.0, (sum, t) => sum + t.amount);
              return bucket.copyWith(spent: bucketSpent);
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: _isCurrentMonth
                  ? FloatingActionButton(
                      onPressed: () => _onAddTransaction(calculatedBuckets),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  : null,
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
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
                    if (!_isCurrentMonth &&
                        !_isFutureMonth &&
                        !_isInspectingPast)
                      PastMonthSummary(
                        selectedDate: _selectedDate,
                        income: monthlyIncome,
                        expense: monthlyExpense,
                        isDark: isDark,
                        onBackToToday: () =>
                            setState(() => _selectedDate = DateTime.now()),
                        onInspect: () =>
                            setState(() => _isInspectingPast = true),
                      )
                    else
                      FinanceDashboard(
                        isDark: isDark,
                        showChart: _showChart,
                        transactions: monthTransactions,
                        buckets: calculatedBuckets,
                        monthlyIncome: monthlyIncome,
                        monthlyExpense: monthlyExpense,
                        onEditTransaction: (tx) =>
                            _onEditTransaction(tx, calculatedBuckets),
                        onUpdateBucketLimit: _updateBucketLimit,
                        onEditAllBudgets: () =>
                            _showEditMonthlyBudgets(calculatedBuckets),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
