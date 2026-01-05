import 'package:flutter/material.dart';
import 'budget_progress_bar.dart'; // IMPORT

class BucketList extends StatelessWidget {
  final List<dynamic> buckets;
  final String? selectedBucketId;
  final Function(String?) onBucketSelected;

  const BucketList({
    super.key,
    required this.buckets,
    required this.selectedBucketId,
    required this.onBucketSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: buckets.length,
      itemBuilder: (context, index) {
        final bucket = buckets[index];
        final isSelected = selectedBucketId == bucket.id;

        return GestureDetector(
          onTap: () => onBucketSelected(isSelected ? null : bucket.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 140,
            margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? bucket.color.withOpacity(0.1) : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: bucket.color, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Icon
                Icon(bucket.icon, color: bucket.color, size: 28),

                // Middle: Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bucket.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${bucket.spent.toInt()}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                // Bottom: Complex Bar
                BudgetProgressBar(
                  spent: bucket.spent,
                  limit: bucket.limit,
                  color: bucket.color,
                  isFixed: bucket.isFixed,
                  showLabels:
                      false, // Keep card clean, detailed view is in header
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
