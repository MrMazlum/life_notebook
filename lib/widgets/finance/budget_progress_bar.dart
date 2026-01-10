import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final Color color;
  final bool isFixed;
  final bool showLabels;
  final double? customIdeal;
  final double height;
  final bool isFuture; // <--- NEW PARAMETER

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
    required this.color,
    this.isFixed = false,
    this.showLabels = true,
    this.customIdeal,
    this.height = 12,
    this.isFuture = false, // <--- DEFAULT FALSE
  });

  @override
  Widget build(BuildContext context) {
    if (limit <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- FIX LOGIC HERE ---
    double dayProgress;
    if (isFuture) {
      dayProgress = 0.0; // Future: Month hasn't started
    } else {
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      dayProgress = (now.day / daysInMonth).clamp(0.0, 1.0);
    }
    // ---------------------

    final spendProgress = (spent / limit).clamp(0.0, 1.0);
    final idealSpend = customIdeal ?? (limit * dayProgress);
    final idealProgress = (idealSpend / limit).clamp(0.0, 1.0);

    // Status Text Logic
    final diffAmount = spent - idealSpend;
    final diffPercent = (diffAmount / limit) * 100;

    String statusText;
    Color statusColor;

    if (isFuture) {
      // Clean status for future
      statusText = "Ready to start";
      statusColor = Colors.grey;
    } else if (isFixed) {
      if (spent >= limit) {
        statusText = "✅ Paid";
        statusColor = Colors.green;
      } else {
        statusText = "⏳ Pending";
        statusColor = Colors.orange;
      }
    } else {
      if (diffPercent > 5) {
        statusText = "⚠️ +${diffPercent.toInt()}% ahead";
        statusColor = Colors.redAccent;
      } else if (diffPercent < -5) {
        statusText = "✅ ${diffPercent.abs().toInt()}% under";
        statusColor = Colors.green;
      } else {
        statusText = "👌 On Track";
        statusColor = Colors.green;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: width * spendProgress,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                  // Hide white indicator if future
                  if (!isFixed && !isFuture)
                    Positioned(
                      left: (width * idealProgress).clamp(0, width - 2),
                      child: Container(
                        width: 2,
                        height: height,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(spendProgress * 100).toInt()}% used",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
