import 'package:flutter/material.dart';
import '../models/lesson.dart';

class ClassCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onDelete; // NEW: Callback for delete action

  const ClassCard({super.key, required this.lesson, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    final typeColor = lesson.isLecture ? primaryColor : Colors.teal;
    final typeIcon = lesson.isLecture
        ? Icons.class_outlined
        : (lesson.name.toLowerCase().contains('gym')
              ? Icons.fitness_center
              : Icons.edit_note);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Time Column
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

          // B. Visual Line
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                  ),
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

          // C. Content Card
          Expanded(
            child: Card(
              color: cardBgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Name & DELETE BUTTON
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
                        // DELETE BUTTON
                        if (onDelete != null)
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Context info
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

                    const SizedBox(height: 8),
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${lesson.durationInMinutes} min",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
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
