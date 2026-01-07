import 'package:flutter/material.dart';
import '../../models/finance_models.dart';

class EditMonthlyBudgetDialog extends StatefulWidget {
  final List<FinanceBucket> buckets;
  final Function(String, double, String, VoidCallback) onUpdateLimit;

  const EditMonthlyBudgetDialog({
    super.key,
    required this.buckets,
    required this.onUpdateLimit,
  });

  @override
  State<EditMonthlyBudgetDialog> createState() =>
      _EditMonthlyBudgetDialogState();
}

class _EditMonthlyBudgetDialogState extends State<EditMonthlyBudgetDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final totalLimit = widget.buckets.fold(0.0, (sum, b) => sum + b.limit);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Monthly Budgets",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.buckets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bucket = widget.buckets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bucket.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bucket.icon, size: 18, color: bucket.color),
                    ),
                    title: Text(
                      bucket.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "\$${bucket.limit.toStringAsFixed(0)}",
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                    onTap: () {
                      widget.onUpdateLimit(
                        bucket.id,
                        bucket.limit,
                        bucket.name,
                        () => setState(() {}),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Budget",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "\$${totalLimit.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Done",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
