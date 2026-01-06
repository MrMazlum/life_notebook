import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';

class TransactionList extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final List<FinanceBucket> buckets;
  final bool isDark;
  final Function(FinanceTransaction) onEdit;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.buckets,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "No transactions yet.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        FinanceBucket? bucket;
        if (tx.isExpense) {
          try {
            bucket = buckets.firstWhere((b) => b.id == tx.categoryId);
          } catch (_) {}
        }

        final color = tx.isExpense
            ? (bucket?.color ?? Colors.grey)
            : (tx.color ?? Colors.green);

        final icon = tx.isExpense
            ? (bucket?.icon ?? Icons.category)
            : (tx.icon ?? Icons.attach_money);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(tx.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // FIX 3: RESTORED RED COLOR FOR EXPENSES
                  Text(
                    "${tx.isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: tx.isExpense
                          ? Colors
                                .redAccent // Explicitly Red
                          : Colors.green, // Explicitly Green
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => onEdit(tx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
