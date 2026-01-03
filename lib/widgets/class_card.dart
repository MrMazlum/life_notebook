import 'package:flutter/material.dart';
import '../models/lesson.dart';

class ClassCard extends StatelessWidget {
  final Lesson lesson;
  const ClassCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final String endTime = lesson.getEndTimeString();
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = Colors.grey;
    final Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Timeline - Time
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lesson.startTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  "|",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                Text(
                  endTime,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          // Timeline - Line & Dot
          Column(
            children: [
              Container(
                height: 50,
                width: 2,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                  ),
                ),
              ),
              Container(
                height: 50,
                width: 2,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ],
          ),
          // Content Card
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(
                          lesson.room,
                          style: TextStyle(fontSize: 14, color: subTextColor),
                        ),
                        const Spacer(),
                        Icon(Icons.person, size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(
                          lesson.instructor,
                          style: TextStyle(fontSize: 14, color: subTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${lesson.durationMinutes} min",
                        style: TextStyle(fontSize: 10, color: primaryColor),
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
