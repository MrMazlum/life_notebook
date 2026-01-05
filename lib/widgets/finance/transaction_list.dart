import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final List<dynamic> transactions;
  final List<dynamic> buckets;
  final bool isDark;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.buckets,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            "No transactions.",
            style: TextStyle(color: subTextColor),
          ),
        ),
      );
    }

    // Grouping Logic
    final Map<int, List<dynamic>> weeklyGroups = {};
    for (var t in transactions) {
      final dayOfYear = int.parse(DateFormat("D").format(t.date));
      final weekNum = (dayOfYear / 7).ceil();
      weeklyGroups.putIfAbsent(weekNum, () => []).add(t);
    }
    final sortedWeeks = weeklyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedWeeks.map((weekNum) {
        final weekTransactions = weeklyGroups[weekNum]!;
        weekTransactions.sort((a, b) => b.date.compareTo(a.date));

        final weekTotal = weekTransactions.fold(
          0.0,
          (sum, t) => sum + (t.isExpense ? -t.amount : t.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW DESIGN: Sleek Week Header
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Week $weekNum",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: subTextColor,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${weekTotal >= 0 ? '+' : ''}\$${weekTotal.abs().toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: weekTotal >= 0
                          ? Colors.green
                          : (isDark ? Colors.redAccent.shade100 : Colors.red),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // List Items
            ...weekTransactions
                .map((t) => _buildTransactionCard(t, context))
                .toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionCard(dynamic t, BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    Color color;
    IconData icon;

    if (t.isExpense) {
      dynamic bucket;
      try {
        bucket = buckets.firstWhere((b) => b.id == t.categoryId);
      } catch (e) {
        bucket = null;
      }
      color = bucket != null ? bucket.color : Colors.grey;
      icon = bucket != null ? bucket.icon : Icons.help_outline;
    } else {
      color = t.color ?? Colors.green;
      icon = t.icon ?? Icons.attach_money;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 0,
        ), // Tighter padding
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          t.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d').format(t.date),
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
        trailing: Text(
          "${t.isExpense ? '-' : '+'}\$${t.amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: t.isExpense ? Colors.redAccent : Colors.green,
          ),
        ),
      ),
    );
  }
}
