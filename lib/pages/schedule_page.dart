import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson.dart';
import '../widgets/schedule/add_lesson_dialog.dart';
import '../widgets/schedule/timeline_item.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _lessonsStream = _lessonsRef
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _lessonsStream = const Stream.empty();
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final querySnapshot = await _lessonsRef
        .where('userId', isEqualTo: user.uid)
        .where('name', isEqualTo: courseName)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'instructor': newInstructor});
    }
    await batch.commit();
  }

  void _handleDeleteRequest(String lessonId) {
    _lessonsRef.doc(lessonId).get().then((doc) {
      if (doc.exists) {
        final lesson = Lesson.fromFirestore(doc);
        _confirmDeleteLogic(lesson);
      }
    });
  }

  void _confirmDeleteLogic(Lesson lesson) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_forever,
                  size: 32,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Delete Event?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure?",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        if (lesson.isRecurring) {
                          _lessonsRef.doc(lesson.id).update({
                            'excludeDates': FieldValue.arrayUnion([dateString]),
                          });
                        } else {
                          _lessonsRef.doc(lesson.id).delete();
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
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
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: bgColor,
      // RESTORED: Purple + FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLessonDialog(),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. CALENDAR HEADER (Restored to Top)
            CalendarHeader(
              selectedDate: _selectedDate,
              onDateSelected: (newDate) =>
                  setState(() => _selectedDate = newDate),
            ),

            const SizedBox(height: 10),

            // 2. TIMELINE LIST
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

                  // Smart DB Update
                  _smartCourseDatabase = {};
                  for (var l in allLessons) {
                    if (l.isLecture && l.name.isNotEmpty) {
                      _smartCourseDatabase[l.name] = l.instructor;
                    }
                  }

                  // Filter for Selected Date
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No plans for $dayName.",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Determine "Active" Lesson
                  final now = DateTime.now();
                  final currentMinutes = now.hour * 60 + now.minute;
                  int activeIndex = -1;

                  if (DateUtils.isSameDay(_selectedDate, now)) {
                    for (int i = 0; i < daysLessons.length; i++) {
                      if (daysLessons[i].endTimeInMinutes > currentMinutes) {
                        activeIndex = i;
                        break;
                      }
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    itemCount: daysLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = daysLessons[index];
                      return TimelineItem(
                        lesson: lesson,
                        isFirst: index == 0,
                        isLast: index == daysLessons.length - 1,
                        isActive: index == activeIndex,
                        onTap: () => _openLessonDialog(lesson: lesson),
                      );
                    },
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
