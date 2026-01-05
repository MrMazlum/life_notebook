import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final Color color;
  final bool isFixed; // True for Rent, False for Food
  final bool showLabels;
  final double? customIdeal; // NEW: Override the math for the Total Bar

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
    required this.color,
    this.isFixed = false,
    this.showLabels = true,
    this.customIdeal, // NEW
  });

  @override
  Widget build(BuildContext context) {
    if (limit <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Time Calculations
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final dayProgress = now.day / daysInMonth;

    // 2. Money Calculations
    final spendProgress = (spent / limit).clamp(0.0, 1.0);

    // SMART LOGIC: Use custom ideal if provided (for Total Bar), else calculate
    final idealSpend = customIdeal ?? (limit * dayProgress);
    final idealProgress = (idealSpend / limit).clamp(0.0, 1.0);

    final diffAmount = spent - idealSpend;
    final diffPercent = (diffAmount / limit) * 100;

    // 3. Status Logic
    String statusText;
    Color statusColor;

    if (isFixed) {
      // Fixed Logic (Rent)
      if (spent >= limit) {
        statusText = "✅ Paid";
        statusColor = Colors.green;
      } else {
        statusText = "⏳ Pending";
        statusColor = Colors.orange;
      }
    } else {
      // Fluid Logic (Food) OR Mixed (Total)
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
        // THE BAR STACK
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // A. Background
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  // B. Actual Spending
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: width * spendProgress,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  // C. "Ideal" Line Marker (Show for Fluid or Mixed)
                  if (!isFixed)
                    Positioned(
                      left: (width * idealProgress).clamp(0, width - 2),
                      child: Container(
                        width: 2,
                        height: 12,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // LABELS
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
