import 'package:flutter/material.dart';
import '../../models/lesson.dart';

class TimelineItem extends StatelessWidget {
  final Lesson lesson;
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final VoidCallback onTap;

  const TimelineItem({
    super.key,
    required this.lesson,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (lesson.category) {
      case 'gym':
        return Icons.fitness_center;
      case 'food':
        return Icons.restaurant;
      case 'read':
        return Icons.menu_book;
      case 'coffee':
        return Icons.coffee;
      case 'work':
        return Icons.work;
      case 'class':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors
    final Color themeColor = Color(lesson.colorValue);
    final Color cardColor = isActive
        ? themeColor.withOpacity(0.8)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final Color titleColor = isActive
        ? Colors.white
        : (isDark ? Colors.white : Colors.black);
    final Color subtitleColor = isActive ? Colors.white70 : Colors.grey;

    // --- LOGIC TO DETERMINE SUBTITLE ---
    String subtitle = "";
    if (lesson.isLecture) {
      // For lectures, we generally want to show info, even if partial
      List<String> parts = [];
      if (lesson.room.isNotEmpty) parts.add(lesson.room);
      if (lesson.instructor.isNotEmpty) parts.add(lesson.instructor);
      subtitle = parts.join(" • ");
    } else {
      // For tasks, only show if description exists
      subtitle = lesson.description;
    }
    // -----------------------------------

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TIME COLUMN (Centered)
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                lesson.startTimeString,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. LINE & DOT (Centered)
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst
                      ? Colors.transparent
                      : Colors.deepPurple.withOpacity(0.3),
                ),
              ),
              Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.black : Colors.white,
                  border: Border.all(color: themeColor, width: 3),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : Colors.deepPurple.withOpacity(0.3),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // 3. CARD CONTENT
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 11),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: themeColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.2)
                            : themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: isActive ? Colors.white : themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center Vertically if no subtitle
                        children: [
                          Text(
                            lesson.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          // Only render subtitle if it exists
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
