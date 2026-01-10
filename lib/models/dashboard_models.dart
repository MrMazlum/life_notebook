import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'lesson.dart';

class DashboardModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _dateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // --- STREAMS ---

  Stream<Map<String, dynamic>> getDailyHealth() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('health_logs')
        .doc(_dateKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return {'steps': 0, 'calories': 0, 'waterLiters': 0.0};
          }
          final data = snapshot.data()!;
          int glasses = data['waterGlasses'] ?? 0;
          int size = data['waterGlassSizeMl'] ?? 250;
          return {
            'steps': data['steps'] ?? 0,
            'calories': data['totalCalories'] ?? 0,
            'waterLiters': (glasses * size) / 1000,
          };
        });
  }

  // FIXED: Handles filtering client-side to avoid Indexing glitches
  Stream<double> getDailySpend() {
    return _db
        .collection('finance_transactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .limit(50) // Fetch recent transactions
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          final now = DateTime.now();

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final Timestamp? ts = data['date'];

            if (ts != null) {
              final date = ts.toDate();
              // Check if it is today
              if (date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day) {
                if (data['isExpense'] == true) {
                  total += (data['amount'] ?? 0.0);
                }
              }
            }
          }
          return total;
        });
  }

  Stream<QuerySnapshot> getCurrentBook() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('books')
        .where('status', isEqualTo: 'reading')
        .limit(1)
        .snapshots();
  }

  Stream<Map<String, dynamic>> getUpNext() {
    return _db
        .collection('lessons')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return _emptyEvent();

          final now = DateTime.now();
          final dayName = DateFormat('EEEE').format(now);
          final dateString = DateFormat('yyyy-MM-dd').format(now);
          final currentMinutes = now.hour * 60 + now.minute;

          List<Lesson> todayLessons = [];

          for (var doc in snapshot.docs) {
            final lesson = Lesson.fromFirestore(doc);
            bool isToday = false;

            if (lesson.isRecurring) {
              if (lesson.dayOfWeek == dayName &&
                  !lesson.excludeDates.contains(dateString)) {
                isToday = true;
              }
            } else {
              if (lesson.specificDate == dateString) {
                isToday = true;
              }
            }

            if (isToday) {
              if (lesson.startTimeInMinutes > currentMinutes) {
                todayLessons.add(lesson);
              }
            }
          }

          todayLessons.sort(
            (a, b) => a.startTimeInMinutes.compareTo(b.startTimeInMinutes),
          );

          if (todayLessons.isNotEmpty) {
            final next = todayLessons.first;
            return {
              'title': next.name,
              'room': next.room.isEmpty ? 'Home' : next.room,
              'startTime': next.startTimeString,
              'endTime': next.endTimeString,
              'hasEvent': true,
            };
          }
          return _emptyEvent();
        });
  }

  Map<String, dynamic> _emptyEvent() {
    return {
      'title': 'No Events',
      'room': 'Free Time',
      'startTime': '--:--',
      'endTime': '',
      'hasEvent': false,
    };
  }

  // --- ACTIONS ---

  Future<void> addTask(String title) async {
    if (title.isEmpty) return;
    final docRef = _db
        .collection('users')
        .doc(_uid)
        .collection('book_logs')
        .doc(_dateKey);
    final newTask = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'isHabit': false,
      'isDone': false,
      'streak': 0,
    };
    await docRef.set({
      'date': Timestamp.now(),
      'tasks': FieldValue.arrayUnion([newTask]),
    }, SetOptions(merge: true));
  }

  Future<void> addIdea(String content) async {
    if (content.isEmpty) return;
    await _db.collection('users').doc(_uid).collection('ideas').add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Used by AddLessonDialog
  Future<void> addLesson(Lesson lesson) async {
    await _db.collection('lessons').add(lesson.toMap());
  }

  // Used by AddLessonDialog
  Future<void> updateGlobalInstructor(
    String courseName,
    String newInstructor,
  ) async {
    final snapshot = await _db
        .collection('lessons')
        .where('userId', isEqualTo: _uid)
        .where('name', isEqualTo: courseName)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'instructor': newInstructor});
    }
    await batch.commit();
  }

  Future<void> updateBookProgress(String bookId, int newPage) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('books')
        .doc(bookId)
        .update({
          'currentPage': newPage,
          'lastRead': FieldValue.serverTimestamp(),
        });
  }
}
