import 'package:flutter/material.dart';
import '../../models/book_models.dart';

class BookSummaryView extends StatelessWidget {
  final BookDailyLog log;
  final VoidCallback onInspect;
  final VoidCallback onBackToToday;

  const BookSummaryView({
    super.key,
    required this.log,
    required this.onInspect,
    required this.onBackToToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitsDone = log.tasks.where((t) => t.isHabit && t.isDone).length;
    final habitsTotal = log.tasks.where((t) => t.isHabit).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICON
            Icon(Icons.auto_stories, size: 64, color: Colors.blue.shade400),
            const SizedBox(height: 16),

            // TITLE
            Text(
              "Daily Recap",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${log.pagesRead} Pages Read",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // STATS GRID
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat(
                  "Tasks",
                  "${log.tasks.where((t) => !t.isHabit && t.isDone).length}/${log.tasks.where((t) => !t.isHabit).length}",
                  isDark,
                ),
                const SizedBox(width: 24),
                _buildStat("Habits", "$habitsDone/$habitsTotal", isDark),
                const SizedBox(width: 24),
                _buildStat("End Page", "${log.endPage}", isDark),
              ],
            ),

            const SizedBox(height: 48),

            // ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBackToToday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      "Back to Today",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onInspect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Theme color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text("Inspect Details"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
