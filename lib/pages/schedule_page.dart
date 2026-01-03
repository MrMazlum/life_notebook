import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import '../widgets/class_card.dart';
import '../widgets/add_lesson_dialog.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String _selectedDay = 'Monday';
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final CollectionReference _lessonsRef = FirebaseFirestore.instance.collection(
    'lessons',
  );

  // --- 1. ADD LESSON ---
  void _addLessonToFirestore(Lesson lesson) {
    _lessonsRef.add(lesson.toMap());
  }

  // --- 2. GLOBAL UPDATE ---
  Future<void> _updateGlobalInstructor(
    String courseName,
    String newInstructor,
  ) async {
    final querySnapshot = await _lessonsRef
        .where('userId', isEqualTo: 'test_user')
        .where('name', isEqualTo: courseName)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'instructor': newInstructor});
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated instructor for ${querySnapshot.docs.length} classes!',
          ),
        ),
      );
    }
  }

  // --- 3. DELETE ---
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lessonsRef.doc(id).delete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return StreamBuilder<QuerySnapshot>(
      stream: _lessonsRef.where('userId', isEqualTo: 'test_user').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLessons =
            snapshot.data?.docs
                .map((doc) => Lesson.fromFirestore(doc))
                .toList() ??
            [];
        final daysLessons = allLessons
            .where((l) => l.dayOfWeek == _selectedDay)
            .toList();
        daysLessons.sort(
          (a, b) => a.startTimeInMinutes.compareTo(b.startTimeInMinutes),
        );

        // SMART DATABASE
        final Map<String, String> smartCourseDatabase = {};
        for (var lesson in allLessons) {
          if (lesson.isLecture && lesson.name.isNotEmpty) {
            smartCourseDatabase[lesson.name] = lesson.instructor;
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddLessonDialog(
                  selectedDay: _selectedDay, // <--- PASSING THE CURRENT DAY
                  courseDatabase: smartCourseDatabase,
                  onAddLesson: _addLessonToFirestore,
                  onUpdateGlobal: _updateGlobalInstructor,
                ),
              );
            },
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    // HEADER
                    Text(
                      _selectedDay,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // DAY SELECTOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _days.map((day) {
                        final isSelected = day == _selectedDay;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  day.substring(0, 3),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // LIST
              Expanded(
                child: daysLessons.isEmpty
                    ? Center(
                        child: Text(
                          "No plans for $_selectedDay. ☕",
                          style: TextStyle(color: Colors.grey.withOpacity(0.8)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: daysLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = daysLessons[index];
                          return ClassCard(
                            lesson: lesson,
                            onDelete: () => _confirmDelete(lesson.id!),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
