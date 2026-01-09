import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookDailyLog {
  final DateTime date;
  List<MindTask> tasks;
  int pagesRead; // Pages read TODAY (delta)
  int endPage; // Page number reached by end of this day (snapshot)

  BookDailyLog({
    DateTime? date,
    List<MindTask>? tasks,
    this.pagesRead = 0,
    this.endPage = 0,
  }) : date = date ?? DateTime.now(),
       tasks = tasks ?? [];

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'pagesRead': pagesRead,
      'endPage': endPage,
    };
  }

  factory BookDailyLog.fromMap(Map<String, dynamic> map, DateTime date) {
    return BookDailyLog(
      date: date,
      tasks: (map['tasks'] as List<dynamic>? ?? [])
          .map((t) => MindTask.fromMap(t))
          .toList(),
      pagesRead: map['pagesRead'] ?? 0,
      endPage: map['endPage'] ?? 0,
    );
  }
}

class MindTask {
  final String id;
  String title;
  bool isDone;
  final bool isHabit;
  final String? reminderTime;

  MindTask({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.isHabit,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'isHabit': isHabit,
    'reminderTime': reminderTime,
  };

  factory MindTask.fromMap(Map<String, dynamic> map) {
    return MindTask(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
      isHabit: map['isHabit'] ?? false,
      reminderTime: map['reminderTime'],
    );
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int totalPages;
  final int currentPage; // Global current page
  final String status;
  final DateTime? lastRead;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    this.lastRead,
  });

  double get progress => totalPages == 0 ? 0 : currentPage / totalPages;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status,
      'lastRead': lastRead ?? FieldValue.serverTimestamp(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    return Book(
      id: id,
      title: map['title'] ?? 'Unknown',
      author: map['author'] ?? 'Unknown',
      coverUrl: map['coverUrl'] ?? '',
      totalPages: map['totalPages'] ?? 100,
      currentPage: map['currentPage'] ?? 0,
      status: map['status'] ?? 'wishlist',
      lastRead: (map['lastRead'] as Timestamp?)?.toDate(),
    );
  }
}

class MindNote {
  final String id;
  String title;
  String body;
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
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory MindNote.fromMap(Map<String, dynamic> map, String id) {
    return MindNote(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      tag: map['tag'] ?? 'General',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
