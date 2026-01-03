import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../widgets/class_card.dart';
import '../widgets/add_lesson_dialog.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // 1. DYNAMIC DATABASE
  final Map<String, String> _courseDatabase = {
    'Linear Algebra': 'Dr. Alan Turing',
    'Physics II': 'Dr. Marie Curie',
    'History': 'Mr. Herodotus',
    'English': 'Mr. Shakespeare',
    'Flutter Development': 'Mr. Mazlum',
    'Gym / Sports': 'Coach Arnold',
    'Lunch Break': '-',
  };

  // 2. THE SCHEDULE
  List<Lesson> myLessons = [
    Lesson(
      name: 'Linear Algebra',
      startTime: '09:00',
      durationMinutes: 90,
      room: 'B-204',
      instructor: 'Dr. Alan Turing',
    ),
  ];

  void _showAddLessonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddLessonDialog(
          courseDatabase: _courseDatabase,
          currentLessons: myLessons,

          onAddLesson: (newLesson) {
            if (_hasConflict(newLesson)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conflict detected! ⛔'),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              setState(() {
                myLessons.add(newLesson);
                myLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
              });
            }
          },

          onSaveCourse: (name, instructor) {
            setState(() {
              _courseDatabase[name] = instructor;
            });
          },

          onDeleteCourse: (courseName, deleteFromSchedule) {
            setState(() {
              _courseDatabase.remove(courseName);

              if (deleteFromSchedule) {
                myLessons.removeWhere((lesson) => lesson.name == courseName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted $courseName and all scheduled classes.',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $courseName from database only.'),
                  ),
                );
              }
            });
          },
        );
      },
    );
  }

  bool _hasConflict(Lesson newLesson) {
    final newStartParts = newLesson.startTime.split(':');
    final newStartMin =
        int.parse(newStartParts[0]) * 60 + int.parse(newStartParts[1]);
    final newEndMin = newStartMin + newLesson.durationMinutes;

    for (var lesson in myLessons) {
      final existingStartParts = lesson.startTime.split(':');
      final existingStartMin =
          int.parse(existingStartParts[0]) * 60 +
          int.parse(existingStartParts[1]);
      final existingEndMin = existingStartMin + lesson.durationMinutes;

      if (newStartMin < existingEndMin && newEndMin > existingStartMin) {
        return true;
      }
    }
    return false;
  }

  void _deleteLesson(int index) {
    setState(() {
      myLessons.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Using colorScheme.primary to ensure vibrant purple in Dark Mode
    final vibrantColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLessonDialog,
        backgroundColor: vibrantColor, // Forces the purple color
        foregroundColor: isDark ? Colors.black : Colors.white, // Icon color
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Text(
              'Manage your classes & professors',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: myLessons.isEmpty
                  ? Center(
                      child: Text(
                        "No classes today! 🎉",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: myLessons.length,
                      itemBuilder: (context, index) {
                        final lesson = myLessons[index];
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) => _deleteLesson(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: ClassCard(lesson: lesson),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
