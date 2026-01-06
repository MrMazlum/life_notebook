import 'package:flutter/material.dart';
import '../../models/lesson.dart';

class ClassCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onEdit; // Renamed from onDelete to onEdit

  const ClassCard({super.key, required this.lesson, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final typeColor = lesson.isLecture ? primaryColor : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  lesson.startTimeString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.endTimeString,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // LINE
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 90,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // CARD
          Expanded(
            child: Card(
              color: cardBgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // EDIT BUTTON
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (lesson.isLecture) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.room,
                            style: TextStyle(fontSize: 14, color: subTextColor),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 14, color: subTextColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.instructor,
                              style: TextStyle(
                                fontSize: 14,
                                color: subTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (lesson.description.isNotEmpty)
                        Text(
                          lesson.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
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
