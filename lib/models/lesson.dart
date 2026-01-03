import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String? id;
  final String userId;
  final String name;
  final String room;
  final String instructor;
  final String description;
  final bool isLecture;
  final bool isRecurring; //
  final String dayOfWeek;
  final int startTimeInMinutes;
  final int durationInMinutes;

  Lesson({
    this.id,
    required this.userId,
    required this.name,
    this.room = '',
    this.instructor = '',
    this.description = '',
    this.isLecture = true,
    this.isRecurring = true, // Default to true (Weekly schedule)
    required this.dayOfWeek,
    required this.startTimeInMinutes,
    required this.durationInMinutes,
  });

  // Helpers
  int get endTimeInMinutes => startTimeInMinutes + durationInMinutes;

  String get startTimeString {
    final h = startTimeInMinutes ~/ 60;
    final m = startTimeInMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endTimeString {
    final endMin = startTimeInMinutes + durationInMinutes;
    final h = endMin ~/ 60;
    final m = endMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'room': room,
      'instructor': instructor,
      'description': description,
      'isLecture': isLecture,
      'isRecurring': isRecurring,
      'dayOfWeek': dayOfWeek,
      'startTimeInMinutes': startTimeInMinutes,
      'durationInMinutes': durationInMinutes,
    };
  }

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lesson(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      room: data['room'] ?? '',
      instructor: data['instructor'] ?? '',
      description: data['description'] ?? '',
      isLecture: data['isLecture'] ?? true,
      isRecurring: data['isRecurring'] ?? true,
      dayOfWeek: data['dayOfWeek'] ?? 'Monday',
      startTimeInMinutes: data['startTimeInMinutes'] ?? 0,
      durationInMinutes: data['durationInMinutes'] ?? 60,
    );
  }
}
