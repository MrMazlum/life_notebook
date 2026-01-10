import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// MODELS
import '../models/finance_models.dart';

// WIDGETS
import '../widgets/finance/add_transaction_dialog.dart';
import '../widgets/finance/past_month_summary.dart';
import '../widgets/finance/finance_dashboard.dart';
import '../widgets/finance/edit_monthly_budget_dialog.dart';
import '../widgets/finance/finance_header.dart';
import '../widgets/finance/future_month_planner.dart'; // <--- NEW WIDGET IMPORT

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isInspectingPast = false;
  bool _showChart = false;

  // NEW: Toggle for when user decides to "Unlock" a future month
  bool _isPlanningMode = false;

  // Default to Euro
  String _currencySymbol = '€';

  final CollectionReference _bucketsRef = FirebaseFirestore.instance.collection(
    'finance_buckets',
  );
  final CollectionReference _txRef = FirebaseFirestore.instance.collection(
    'finance_transactions',
  );

  @override
  void initState() {
    super.initState();
    _ensureBucketsExist();
    _loadUserCurrency();
  }

  // LOAD SAVED CURRENCY
  Future<void> _loadUserCurrency() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('currencySymbol')) {
        if (mounted) {
          setState(() {
            _currencySymbol = doc.data()!['currencySymbol'];
          });
        }
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
      _isPlanningMode = false; // <--- Reset "Plan" mode when switching months
    });
  }

  Future<void> _ensureBucketsExist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await _bucketsRef
        .where('userId', isEqualTo: user.uid)
        .get();
    if (snapshot.docs.isEmpty) {
      final defaults = [
        FinanceBucket(
          id: '',
          name: 'Groceries',
          limit: 300,
          iconCode: 57522, // Shopping cart
          colorValue: Colors.orange.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Transport',
          limit: 100,
          iconCode: 57563, // Bus
          colorValue: Colors.blue.value,
        ),
        FinanceBucket(
          id: '',
          name: 'Fun',
          limit: 150,
          iconCode: 57366, // Ticket
          colorValue: Colors.purple.value,
        ),
      ];

      for (var b in defaults) {
        await _bucketsRef.add(b.toMap());
      }
    }
  }

  // --- CURRENCY PICKER ---
  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currencies = [
          '\$',
          '€',
          '£',
          '¥',
          '₺',
          '₹',
          '₽',
          '₩',
          'R\$',
          '฿',
          '₫',
          'Rp',
          '₪',
          'kr',
          'Fr',
          'zł',
          'R',
          '₱',
          '₦',
          'C\$',
        ];

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Currency",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: currencies.length,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final symbol = currencies[index];
                    final isSelected = _currencySymbol == symbol;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _currencySymbol = symbol);

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set({
                                'currencySymbol': symbol,
                              }, SetOptions(merge: true));
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                  labelText: "Monthly Limit ($_currencySymbol)",
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
        currencySymbol: _currencySymbol,
      ),
    );
  }

  void _onEditTransaction(FinanceTransaction tx, List<FinanceBucket> buckets) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        buckets: buckets,
        transactionToEdit: tx,
        currencySymbol: _currencySymbol,
      ),
    );
  }

  void _onAddTransaction(List<FinanceBucket> buckets) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        buckets: buckets,
        currencySymbol: _currencySymbol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: _bucketsRef.where('userId', isEqualTo: user.uid).snapshots(),
      builder: (context, bucketSnap) {
        if (!bucketSnap.hasData)
          return const Center(child: CircularProgressIndicator());

        final buckets = bucketSnap.data!.docs
            .map((doc) => FinanceBucket.fromFirestore(doc))
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _txRef
              .where('userId', isEqualTo: user.uid)
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, txSnap) {
            if (!txSnap.hasData)
              return const Center(child: CircularProgressIndicator());

            final allTransactions = txSnap.data!.docs
                .map((doc) => FinanceTransaction.fromFirestore(doc))
                .toList();
            final monthTransactions = allTransactions
                .where(
                  (t) =>
                      t.date.year == _selectedDate.year &&
                      t.date.month == _selectedDate.month,
                )
                .toList();

            final monthlyExpense = monthTransactions
                .where((t) => t.isExpense)
                .fold(0.0, (sum, t) => sum + t.amount);
            final monthlyIncome = monthTransactions
                .where((t) => !t.isExpense)
                .fold(0.0, (sum, t) => sum + t.amount);

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
                        _isPlanningMode = false;
                      }),
                      onSettingsTap: _showCurrencyPicker,
                    ),

                    // --- VIEW LOGIC SWITCHER ---
                    if (!_isCurrentMonth &&
                        !_isFutureMonth &&
                        !_isInspectingPast)
                      // 1. PAST MONTH VIEW
                      PastMonthSummary(
                        selectedDate: _selectedDate,
                        income: monthlyIncome,
                        expense: monthlyExpense,
                        isDark: isDark,
                        currencySymbol: _currencySymbol,
                        onBackToToday: () =>
                            setState(() => _selectedDate = DateTime.now()),
                        onInspect: () =>
                            setState(() => _isInspectingPast = true),
                      )
                    else if (_isFutureMonth && !_isPlanningMode)
                      // 2. FUTURE MONTH (LOCKED) VIEW - NEW!
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: FutureMonthPlanner(
                          selectedDate: _selectedDate,
                          onPlan: () {
                            setState(() {
                              _isPlanningMode = true; // Unlock dashboard
                            });
                          },
                        ),
                      )
                    else
                      // 3. DASHBOARD VIEW (Current, Planning, or Inspected)
                      FinanceDashboard(
                        isDark: isDark,
                        showChart: _showChart,
                        transactions: monthTransactions,
                        buckets: calculatedBuckets,
                        monthlyIncome: monthlyIncome,
                        monthlyExpense: monthlyExpense,
                        currencySymbol: _currencySymbol,
                        // NEW: Pass the flag to hide the white bar!
                        isFuture: _isFutureMonth,
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
