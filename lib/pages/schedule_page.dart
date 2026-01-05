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

  // FIX: This variable stores the course info so FAB can access it
  Map<String, String> _smartCourseDatabase = {};

  @override
  void initState() {
    super.initState();
    _lessonsStream = _lessonsRef
        .where('userId', isEqualTo: 'test_user')
        .snapshots();
  }

  void _addLessonToFirestore(Lesson lesson) {
    _lessonsRef.add(lesson.toMap());
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
        SnackBar(
          content: Text(
            'Updated instructor for ${querySnapshot.docs.length} classes!',
          ),
        ),
      );
    }
  }

  void _confirmDelete(Lesson lesson) {
    if (!lesson.isRecurring) {
      _deleteForever(lesson.id!);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("Delete Event"),
        content: Text(
          "Do you want to delete this specific session or the entire series?",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOnlyThisSession(lesson.id!, dateString);
            },
            child: Text("Only This", style: TextStyle(color: accentColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteForever(lesson.id!);
            },
            child: const Text(
              "All Future",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _deleteForever(String id) {
    _lessonsRef.doc(id).delete();
  }

  void _deleteOnlyThisSession(String id, String dateToExclude) {
    _lessonsRef.doc(id).update({
      'excludeDates': FieldValue.arrayUnion([dateToExclude]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;

    final String dayName = DateFormat('EEEE').format(_selectedDate);
    final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // NOW PASSING THE REAL DATABASE
          showDialog(
            context: context,
            builder: (_) => AddLessonDialog(
              selectedDate: _selectedDate,
              courseDatabase: _smartCourseDatabase,
              onAddLesson: _addLessonToFirestore,
              onUpdateGlobal: _updateGlobalInstructor,
            ),
          );
        },
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

                // FIX: Populate the member variable for the FAB to use
                _smartCourseDatabase = {};
                for (var lesson in allLessons) {
                  if (lesson.isLecture && lesson.name.isNotEmpty) {
                    _smartCourseDatabase[lesson.name] = lesson.instructor;
                  }
                }

                final daysLessons = allLessons.where((l) {
                  if (l.isRecurring) {
                    return l.dayOfWeek == dayName &&
                        !l.excludeDates.contains(dateString);
                  } else {
                    return l.specificDate == dateString;
                  }
                }).toList();

                daysLessons.sort(
                  (a, b) =>
                      a.startTimeInMinutes.compareTo(b.startTimeInMinutes),
                );

                if (daysLessons.isEmpty) {
                  return Center(
                    child: Text(
                      "No plans for $dayName. ☕",
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
                      onDelete: () => _confirmDelete(lesson),
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
