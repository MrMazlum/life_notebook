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

    // LOGIC FIX: Prevent negative pages if data is corrupted
    final int displayPages = log.pagesRead < 0 ? 0 : log.pagesRead;

    final habitsDone = log.tasks.where((t) => t.isHabit && t.isDone).length;
    final habitsTotal = log.tasks.where((t) => t.isHabit).length;
    final taskCount = log.tasks.where((t) => !t.isHabit).length;
    final tasksDone = log.tasks.where((t) => !t.isHabit && t.isDone).length;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. HEADER ICON
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_edu,
                  size: 40,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 16),

              // 2. TITLE & PAGES
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
                "$displayPages Pages Read",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // 3. STATS GRID (Replaces empty text)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Tasks",
                      "$tasksDone/$taskCount",
                      Icons.check_box_outlined,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Habits",
                      "$habitsDone/$habitsTotal",
                      Icons.loop,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "End Page",
                      "${log.endPage}",
                      Icons.bookmark_outline,
                      isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. HABIT SNAPSHOT (Visual List)
              if (habitsTotal > 0) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Habit Log",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: log.tasks
                        .where((t) => t.isHabit)
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  h.isDone ? Icons.check_circle : Icons.cancel,
                                  color: h.isDone ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  h.title,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // 5. ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBackToToday,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
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
                        backgroundColor: Colors.blue,
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
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
