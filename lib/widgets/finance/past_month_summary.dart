import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastMonthSummary extends StatelessWidget {
  final DateTime selectedDate;
  final double income;
  final double expense;
  final bool isDark;
  final String currencySymbol; // <--- NEW PARAMETER
  final VoidCallback onBackToToday;
  final VoidCallback onInspect;

  const PastMonthSummary({
    super.key,
    required this.selectedDate,
    required this.income,
    required this.expense,
    required this.isDark,
    required this.currencySymbol, // <--- REQUIRED HERE
    required this.onBackToToday,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Colors.green;
    final netSavings = income - expense;
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
                      ? "You saved $currencySymbol${netSavings.toStringAsFixed(0)} in ${DateFormat('MMMM').format(selectedDate)}."
                      : "You spent $currencySymbol${netSavings.abs().toStringAsFixed(0)} more than you earned.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Income", income, Colors.green),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    _buildStatItem("Expense", expense, Colors.redAccent),
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
                  onPressed: onBackToToday,
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
                  onPressed: onInspect,
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
          "$currencySymbol${amount.toStringAsFixed(0)}", // <--- USED SYMBOL HERE
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
