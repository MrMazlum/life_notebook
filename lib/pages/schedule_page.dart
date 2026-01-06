import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/lesson.dart';
import '../widgets/schedule/class_card.dart';
import '../widgets/schedule/add_lesson_dialog.dart';
import '../widgets/schedule/calendar_header.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  final CollectionReference _lessonsRef = FirebaseFirestore.instance.collection(
    'lessons',
  );
  late Stream<QuerySnapshot> _lessonsStream;
  Map<String, String> _smartCourseDatabase = {};

  @override
  void initState() {
    super.initState();
    _lessonsStream = _lessonsRef
        .where('userId', isEqualTo: 'test_user')
        .snapshots();
  }

  void _saveLessonToFirestore(Lesson lesson) {
    if (lesson.id != null) {
      _lessonsRef.doc(lesson.id).update(lesson.toMap());
    } else {
      _lessonsRef.add(lesson.toMap());
    }
  }

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
        const SnackBar(content: Text('Updated global instructors!')),
      );
    }
  }

  // --- DELETE LOGIC & UI ---

  void _handleDeleteRequest(String lessonId) {
    _lessonsRef.doc(lessonId).get().then((doc) {
      if (doc.exists) {
        final lesson = Lesson.fromFirestore(doc);
        _confirmDeleteLogic(lesson);
      }
    });
  }

  // UPDATED: Now shows a beautiful dialog for both recurring and one-time events
  void _confirmDeleteLogic(Lesson lesson) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Common styling for the delete dialog to match "Professor Changed"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    size: 32,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  lesson.isRecurring ? "Delete Recurring?" : "Delete Event?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  lesson.isRecurring
                      ? "Delete only this session or the entire series?"
                      : "Are you sure you want to delete '${lesson.name}'?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                if (lesson.isRecurring) ...[
                  // RECURRING BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx); // Close dialog
                            _lessonsRef.doc(lesson.id).update({
                              'excludeDates': FieldValue.arrayUnion([
                                dateString,
                              ]),
                            });
                          },
                          child: Text(
                            "Only This",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            // This deletes the doc, so it wipes past & future.
                            // Renaming button to "Delete Series" for clarity.
                            _lessonsRef.doc(lesson.id).delete();
                          },
                          child: const Text(
                            "Delete Series",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // ONE-TIME EVENT BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx), // Just cancel
                          child: Text(
                            "Keep",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _lessonsRef.doc(lesson.id).delete();
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // MAIN CANCEL BUTTON (Bottom)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openLessonDialog({Lesson? lesson}) {
    showDialog(
      context: context,
      builder: (_) => AddLessonDialog(
        selectedDate: _selectedDate,
        courseDatabase: _smartCourseDatabase,
        onAddLesson: _saveLessonToFirestore,
        onUpdateGlobal: _updateGlobalInstructor,
        lessonToEdit: lesson,
        onDelete: _handleDeleteRequest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? Colors.deepPurpleAccent
        : Theme.of(context).primaryColor;
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLessonDialog(), // ADD MODE
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          CalendarHeader(
            selectedDate: _selectedDate,
            onDateSelected: (newDate) =>
                setState(() => _selectedDate = newDate),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _lessonsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLessons =
                    snapshot.data?.docs
                        .map((doc) => Lesson.fromFirestore(doc))
                        .toList() ??
                    [];

                // Refresh Smart Database
                _smartCourseDatabase = {};
                for (var l in allLessons) {
                  if (l.isLecture && l.name.isNotEmpty) {
                    _smartCourseDatabase[l.name] = l.instructor;
                  }
                }

                // Filter Logic
                final daysLessons = allLessons.where((l) {
                  if (l.isRecurring) {
                    return l.dayOfWeek == dayName &&
                        !l.excludeDates.contains(dateString);
                  }
                  return l.specificDate == dateString;
                }).toList();

                daysLessons.sort(
                  (a, b) =>
                      a.startTimeInMinutes.compareTo(b.startTimeInMinutes),
                );

                if (daysLessons.isEmpty) {
                  return Center(
                    child: Text(
                      "No plans for $dayName.",
                      style: TextStyle(color: Colors.grey.withOpacity(0.8)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: daysLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = daysLessons[index];
                    return ClassCard(
                      lesson: lesson,
                      onEdit: () =>
                          _openLessonDialog(lesson: lesson), // EDIT MODE
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
