import 'package:flutter/material.dart';
// MODELS
import '../../models/finance_models.dart';
// WIDGETS
import 'budget_progress_bar.dart';
import 'pie_chart_view.dart'; // <--- Critical for ChartData
import 'bucket_list.dart';
import 'transaction_list.dart';

enum FilterType { all, income, expense }

class FinanceDashboard extends StatefulWidget {
  final bool isDark;
  final bool showChart;
  final List<FinanceTransaction> transactions;
  final List<FinanceBucket> buckets;
  final double monthlyIncome;
  final double monthlyExpense;
  final String currencySymbol;
  final bool isFuture; // <--- NEW: Tells dashboard if this is a future month
  final Function(FinanceTransaction) onEditTransaction;
  final Function(String, double, String) onUpdateBucketLimit;
  final VoidCallback onEditAllBudgets;

  const FinanceDashboard({
    super.key,
    required this.isDark,
    required this.showChart,
    required this.transactions,
    required this.buckets,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.currencySymbol,
    this.isFuture = false, // Default to false
    required this.onEditTransaction,
    required this.onUpdateBucketLimit,
    required this.onEditAllBudgets,
  });

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  String? _selectedBucketId;
  FilterType _currentFilter = FilterType.all;

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

  @override
  Widget build(BuildContext context) {
    final subTextColor = widget.isDark ? Colors.white54 : Colors.grey;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final primaryColor = Colors.green;

    // Filter Logic
    List<FinanceTransaction> displayedTransactions = widget.transactions;
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

    // Chart Totals
    final chartTotal = widget.buckets.fold(
      0.0,
      (sum, item) => sum + item.spent,
    );
    final chartData = widget.buckets
        .map((b) => ChartData(b.id, b.name, b.spent, b.color, b.icon))
        .toList();

    // Progress Bar Calculations
    final totalBudgetLimit = widget.buckets.fold(
      0.0,
      (sum, b) => sum + b.limit,
    );
    final totalBudgetSpent = widget.buckets.fold(
      0.0,
      (sum, b) => sum + b.spent,
    );

    // --- FIX: CALCULATE IDEAL SPEND ---
    double totalIdealSpent = 0.0;

    // If it's the future, the "Ideal" spend right now is 0.
    // If it's current/past, we calculate based on days.
    if (!widget.isFuture) {
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final timeProgress = (now.day / daysInMonth).clamp(0.0, 1.0);

      for (var b in widget.buckets) {
        if (b.isFixed) {
          totalIdealSpent += b.limit;
        } else {
          totalIdealSpent += b.limit * timeProgress;
        }
      }
    }
    // ----------------------------------

    FinanceBucket? selectedBucket;
    if (_selectedBucketId != null) {
      try {
        selectedBucket = widget.buckets.firstWhere(
          (b) => b.id == _selectedBucketId,
        );
      } catch (_) {}
    }

    return Column(
      children: [
        // --- SUMMARY CARDS ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Income",
                  widget.monthlyIncome,
                  Colors.green,
                  widget.isDark,
                  FilterType.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Expense",
                  widget.monthlyExpense,
                  Colors.redAccent,
                  widget.isDark,
                  FilterType.expense,
                ),
              ),
            ],
          ),
        ),

        // --- TOTAL BUDGET PROGRESS BAR ---
        if (!widget.showChart)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.green.withOpacity(0.08)
                    : Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Monthly Budget",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onEditAllBudgets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.black26
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Edit All",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 12, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- THE BAR ---
                  BudgetProgressBar(
                    spent: totalBudgetSpent,
                    limit: totalBudgetLimit,
                    color: primaryColor,
                    isFixed: false,
                    customIdeal: totalIdealSpent, // Calculated above
                    isFuture: widget.isFuture, // Pass the flag down
                    height: 24,
                  ),
                ],
              ),
            ),
          ),

        // --- CHART / LIST SWITCHER ---
        const SizedBox(height: 10),
        SizedBox(
          height: widget.showChart ? 320 : 210,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: widget.showChart
                ? PieChartView(
                    key: const ValueKey('chart'),
                    totalSpent: chartTotal,
                    data: chartData,
                    currencySymbol: widget.currencySymbol,
                    onSectionTap: (id) => setState(() {
                      _selectedBucketId = _selectedBucketId == id ? null : id;
                      _currentFilter = FilterType.all;
                    }),
                  )
                : BucketList(
                    key: const ValueKey('list'),
                    buckets: widget.buckets,
                    selectedBucketId: _selectedBucketId,
                    currencySymbol: widget.currencySymbol,
                    onBucketSelected: (id) => setState(() {
                      _selectedBucketId = id;
                      _currentFilter = FilterType.all;
                    }),
                  ),
          ),
        ),

        // --- HISTORY HEADER ---
        const SizedBox(height: 10),
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
                            Flexible(
                              child: Text(
                                selectedBucket.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (selectedBucket == null)
                      Text(
                        "History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    if (selectedBucket != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => widget.onUpdateBucketLimit(
                                selectedBucket!.id,
                                selectedBucket.limit,
                                selectedBucket.name,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 10,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Limit",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectedBucketId = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
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
                                      size: 10,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                        fontSize: 10,
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
                  isFuture: widget.isFuture, // Pass flag here too
                  height: 24,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // --- TRANSACTION LIST ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TransactionList(
            transactions: displayedTransactions,
            buckets: widget.buckets,
            isDark: widget.isDark,
            currencySymbol: widget.currencySymbol,
            onEdit: widget.onEditTransaction,
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
              "${widget.currencySymbol}${amount.toStringAsFixed(0)}",
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
}
