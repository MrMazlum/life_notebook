import 'package:flutter/material.dart';
import '../../models/book_models.dart';

class HabitsSection extends StatelessWidget {
  final List<MindTask> habits;
  final bool isDark;
  final Function(MindTask) onToggle;
  final Function(MindTask) onLongPress;
  final Function(String, bool) onAddGhost;
  final VoidCallback onViewAll;

  const HabitsSection({
    super.key,
    required this.habits,
    required this.isDark,
    required this.onToggle,
    required this.onLongPress,
    required this.onAddGhost,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];

    // 1. Add Real Habits
    for (var habit in habits) {
      items.add(_buildHabitPill(habit, context));
    }

    // 2. Add Ghosts if space permits (< 3 items)
    // ✅ ROBUST CHECK: Normalizes text to lower case for comparison
    if (items.length < 3) {
      if (!habits.any((h) => h.title.toLowerCase().contains("read")))
        items.add(_buildGhostPill("Read 10 pages", Icons.book, context));

      if (items.length < 3 &&
          !habits.any((h) => h.title.toLowerCase().contains("relative")))
        items.add(_buildGhostPill("Call a relative", Icons.call, context));

      if (items.length < 3 &&
          !habits.any((h) => h.title.toLowerCase().contains("exercise")))
        items.add(_buildGhostPill("Exercise", Icons.fitness_center, context));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: Colors.blue.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    "HABITS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => items[i],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPill(MindTask habit, BuildContext context) {
    final isDone = habit.isDone;
    final activeColor = Colors.blue;
    final baseBg = isDark ? const Color(0xFF252525) : Colors.grey.shade50;
    final doneBg = Colors.blue.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: () => onToggle(habit),
      onLongPress: () => onLongPress(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? doneBg : baseBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? activeColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isDone ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDone ? activeColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? activeColor : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                // ✅ STREAK: Number + Fire
                if (isDone)
                  Row(
                    children: [
                      Text(
                        "${habit.streak} ",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ],
                  ),
              ],
            ),
            Text(
              habit.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: isDone
                    ? Colors.blue.shade200
                    : (isDark ? Colors.white : Colors.black87),
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostPill(String text, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () => onAddGhost(text, true),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
