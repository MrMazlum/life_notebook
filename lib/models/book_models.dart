import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int totalPages;
  final int currentPage;
  final String status; // 'reading', 'finished', 'wishlist'
  final double progress;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.totalPages,
    required this.currentPage,
    required this.status,
  }) : progress = totalPages > 0 ? currentPage / totalPages : 0.0;

  factory Book.fromMap(Map<String, dynamic> data, String id) {
    return Book(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      totalPages: data['totalPages'] ?? 0,
      currentPage: data['currentPage'] ?? 0,
      status: data['status'] ?? 'wishlist',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status,
    };
  }
}

class MindTask {
  String id;
  String title;
  bool isHabit;
  bool isDone;
  int streak; // ✅ ADDED STREAK FIELD

  MindTask({
    required this.id,
    required this.title,
    required this.isHabit,
    required this.isDone,
    this.streak = 0, // Default 0
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isHabit': isHabit,
    'isDone': isDone,
    'streak': streak, // Save streak
  };

  factory MindTask.fromMap(Map<String, dynamic> map) => MindTask(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    isHabit: map['isHabit'] ?? false,
    isDone: map['isDone'] ?? false,
    streak: map['streak'] ?? 0, // Load streak
  );
}

class MindNote {
  final String id;
  final String title;
  final String body;
  final String tag;
  final DateTime createdAt;

  MindNote({
    required this.id,
    required this.title,
    required this.body,
    required this.tag,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'tag': tag,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MindNote.fromMap(Map<String, dynamic> map, String id) {
    return MindNote(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      tag: map['tag'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class BookDailyLog {
  DateTime date;
  int pagesRead;
  int endPage;
  List<MindTask> tasks;

  BookDailyLog({
    DateTime? date,
    this.pagesRead = 0,
    this.endPage = 0,
    List<MindTask>? tasks,
  }) : date = date ?? DateTime.now(),
       this.tasks = tasks ?? [];

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'pagesRead': pagesRead,
    'endPage': endPage,
    'tasks': tasks.map((t) => t.toMap()).toList(),
  };

  factory BookDailyLog.fromMap(Map<String, dynamic> map, DateTime date) {
    return BookDailyLog(
      date: date,
      pagesRead: map['pagesRead'] ?? 0,
      endPage: map['endPage'] ?? 0,
      tasks:
          (map['tasks'] as List<dynamic>?)
              ?.map((t) => MindTask.fromMap(t))
              .toList() ??
          [],
    );
  }
}
