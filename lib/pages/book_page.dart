import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_models.dart';
import '../widgets/book/book_hero.dart';
import '../widgets/book/calendar_strip.dart';
import '../widgets/book/book_summary_view.dart';
import '../widgets/book/habits_section.dart';
import '../widgets/book/notes_section.dart';
import '../widgets/book/note_editor_sheet.dart';
import '../widgets/book/all_habits_view.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  // Normalize date to midnight to avoid time mismatches
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  late PageController _weekPageController;
  final int _initialPage = 1000;
  bool _forceInspectMode = false;

  StreamSubscription<DocumentSnapshot>? _logSubscription;
  BookDailyLog _currentLog = BookDailyLog();

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculatePageForDate(DateTime.now());
    _weekPageController = PageController(initialPage: initialIndex);
    _subscribeToDate(_selectedDate);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _logSubscription?.cancel();
    super.dispose();
  }

  // --- 📅 DATE & SUBSCRIPTION LOGIC ---

  void _subscribeToDate(DateTime date) {
    _logSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final normalizedDate = DateUtils.dateOnly(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(normalizedDate);

    _logSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .doc(dateKey)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            if (mounted) {
              setState(
                () => _currentLog = BookDailyLog.fromMap(
                  snapshot.data()!,
                  normalizedDate,
                ),
              );
            }
          } else {
            // If no log exists for this date, initialize it (copy habits)
            _initializeDay(normalizedDate);
          }
        });
  }

  // ✅ HABIT REPETITION: Looks for the LATEST log that is BEFORE today
  Future<void> _initializeDay(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Find the closest PAST log
    final prevLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .where('date', isLessThan: Timestamp.fromDate(date))
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    List<MindTask> inheritedHabits = [];
    if (prevLogs.docs.isNotEmpty) {
      final prevLog = BookDailyLog.fromMap(
        prevLogs.docs.first.data(),
        DateTime.now(),
      );

      inheritedHabits = prevLog.tasks
          .where((t) => t.isHabit)
          .map(
            (t) => MindTask(
              id: t.id, // ✅ KEEP SAME ID TO MAINTAIN STREAK
              title: t.title,
              isHabit: true,
              isDone: false, // Reset done status for new day
              streak: t.isDone
                  ? t.streak
                  : 0, // Carry over streak if done yesterday
            ),
          )
          .toList();
    }

    if (mounted) {
      setState(
        () => _currentLog = BookDailyLog(date: date, tasks: inheritedHabits),
      );
      // Auto-save to create the document so future edits work immediately
      _saveToFirestore();
    }
  }

  // --- 🔥 FIRESTORE ACTIONS ---

  void _saveToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final data = _currentLog.toMap();
    data['date'] = Timestamp.fromDate(_selectedDate); // Needed for sorting

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .doc(dateKey)
        .set(data, SetOptions(merge: true));
  }

  // --- TASKS & HABITS ---

  void _toggleTask(MindTask task) {
    setState(() {
      task.isDone = !task.isDone;
      // Local streak update for immediate feedback
      if (task.isHabit) {
        if (task.isDone)
          task.streak += 1;
        else
          task.streak = (task.streak > 0) ? task.streak - 1 : 0;
      }
    });
    _saveToFirestore();
  }

  Future<void> _addNewTask(String title, bool isHabit) async {
    // Prevent duplicates in current view
    if (_currentLog.tasks.any((t) => t.title == title)) return;

    final newTask = MindTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isHabit: isHabit,
      isDone: false,
      streak: 0,
    );

    setState(() => _currentLog.tasks.add(newTask));
    _saveToFirestore();

    // If adding a habit, propagate to FUTURE days too
    if (isHabit) {
      await _propagateHabitChange(newTask, isDelete: false);
    }
  }

  Future<void> _deleteTask(MindTask task) async {
    setState(() => _currentLog.tasks.removeWhere((t) => t.id == task.id));
    _saveToFirestore();

    // If deleting a habit, remove from FUTURE days too
    if (task.isHabit) {
      await _propagateHabitChange(task, isDelete: true);
    }
  }

  // ✅ Updates FUTURE logs so habits persist or disappear correctly
  Future<void> _propagateHabitChange(
    MindTask task, {
    required bool isDelete,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final futureLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .where('date', isGreaterThan: Timestamp.fromDate(_selectedDate))
        .get();

    if (futureLogs.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in futureLogs.docs) {
      BookDailyLog log = BookDailyLog.fromMap(doc.data(), DateTime.now());

      if (isDelete) {
        log.tasks.removeWhere((t) => t.id == task.id);
      } else {
        // Only add if not already present (ID Check)
        if (!log.tasks.any((t) => t.id == task.id)) {
          log.tasks.add(
            MindTask(
              id: task.id,
              title: task.title,
              isHabit: true,
              isDone: false,
              streak: 0,
            ),
          );
        }
      }
      batch.update(doc.reference, {
        'tasks': log.tasks.map((t) => t.toMap()).toList(),
      });
    }
    await batch.commit();
  }

  void _updateTaskTitle(MindTask task, String newTitle) {
    final idx = _currentLog.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() => _currentLog.tasks[idx].title = newTitle);
      _saveToFirestore();
    }
  }

  // --- BOOK PROGRESS ---

  void _updateBookProgress(String bookId, int delta, int absolutePage) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      int newPagesRead = _currentLog.pagesRead + delta;
      if (newPagesRead < 0) newPagesRead = 0; // Prevent negative
      _currentLog.pagesRead = newPagesRead;
      _currentLog.endPage = absolutePage;
    });
    _saveToFirestore();

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookId)
        .update({
          'currentPage': absolutePage,
          'lastRead': FieldValue.serverTimestamp(),
        });
  }

  // --- UI DIALOGS ---

  void _showInputSheet({required bool isHabit, MindTask? existingTask}) {
    final ctrl = TextEditingController(text: existingTask?.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              existingTask == null
                  ? (isHabit ? "New Habit" : "New Task")
                  : "Edit Item",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Title",
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (existingTask != null) ...[
                  IconButton(
                    onPressed: () {
                      _deleteTask(existingTask);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        if (existingTask != null)
                          _updateTaskTitle(existingTask, ctrl.text);
                        else
                          _addNewTask(ctrl.text, isHabit);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      Icons.check_circle_outline,
                      "Add Task",
                      Colors.green,
                      () {
                        Navigator.pop(ctx);
                        _showInputSheet(isHabit: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(
                      Icons.repeat,
                      "Add Habit",
                      Colors.purple,
                      () {
                        Navigator.pop(ctx);
                        _showInputSheet(isHabit: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(
                      Icons.edit_note_rounded,
                      "Add Note",
                      Colors.blue,
                      () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const NoteEditorSheet(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // --- 🗓️ DATE HELPERS ---

  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = date.subtract(Duration(days: date.weekday - 1));
    return _initialPage + (mondayDate.difference(mondayNow).inDays / 7).round();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _forceInspectMode = false;
    });
    _subscribeToDate(_selectedDate);
  }

  void _handleBackToToday() {
    _onDateSelected(DateTime.now());
    _weekPageController.animateToPage(
      _calculatePageForDate(DateTime.now()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _selectDateFromPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          // ✅ CRITICAL FIX: Explicitly set DatePicker Theme properties
          datePickerTheme: const DatePickerThemeData(
            headerBackgroundColor: Colors.blue, // Forces Header to Blue
            headerForegroundColor: Colors.white, // Forces Header Text to White
            backgroundColor: Color(0xFF1E1E1E), // Dark body background
            surfaceTintColor: Colors.transparent,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue, // Selection circle color
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF1E1E1E),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _onDateSelected(picked);
      _weekPageController.jumpToPage(_calculatePageForDate(picked));
    }
  }

  // --- 🏗️ BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final isPast = _selectedDate.isBefore(DateUtils.dateOnly(DateTime.now()));

    // PAST VIEW MODE
    if (isPast && !_forceInspectMode) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(toolbarHeight: 0, backgroundColor: bgColor),
        body: Column(
          children: [
            CalendarStrip(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
              onBackToToday: _handleBackToToday,
              onPickerTap: _selectDateFromPicker,
              isDark: isDark,
              pageController: _weekPageController,
              themeColor: Colors.blue,
            ),
            Expanded(
              child: BookSummaryView(
                log: _currentLog,
                onInspect: () => setState(() => _forceInspectMode = true),
                onBackToToday: _handleBackToToday,
              ),
            ),
          ],
        ),
      );
    }

    final habits = _currentLog.tasks.where((t) => t.isHabit).toList();
    final chores = _currentLog.tasks.where((t) => !t.isHabit).toList();

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(toolbarHeight: 0, backgroundColor: bgColor),
      body: Column(
        children: [
          // 1. CALENDAR
          CalendarStrip(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
            onBackToToday: _handleBackToToday,
            onPickerTap: _selectDateFromPicker,
            isDark: isDark,
            pageController: _weekPageController,
            themeColor: Colors.blue,
          ),

          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. BOOK HERO (Active + Up Next)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('books')
                        .where('status', isEqualTo: 'reading')
                        .limit(1)
                        .snapshots(),
                    builder: (context, activeSnapshot) {
                      Book? activeBook;
                      if (activeSnapshot.hasData &&
                          activeSnapshot.data!.docs.isNotEmpty) {
                        final doc = activeSnapshot.data!.docs.first;
                        activeBook = Book.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      }
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('books')
                            .where('status', isEqualTo: 'wishlist')
                            .limit(20)
                            .snapshots(),
                        builder: (context, wishlistSnapshot) {
                          final uniqueTitles = <String>{};
                          final upNextBooks =
                              (wishlistSnapshot.data?.docs ?? [])
                                  .map(
                                    (d) => Book.fromMap(
                                      d.data() as Map<String, dynamic>,
                                      d.id,
                                    ),
                                  )
                                  .where(
                                    (b) => uniqueTitles.add(b.title),
                                  ) // Deduplicate visual
                                  .toList();
                          return BookHero(
                            book: activeBook,
                            upNextBooks: upNextBooks,
                            isDark: isDark,
                            onProgressLogged: (delta) {
                              if (activeBook != null)
                                _updateBookProgress(
                                  activeBook.id,
                                  delta,
                                  activeBook.currentPage + delta,
                                );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // B. TASKS (Daily Chores)
                  _buildTasksCard(chores, isDark),

                  const SizedBox(height: 24),

                  // C. HABITS (Streaks)
                  HabitsSection(
                    habits: habits,
                    isDark: isDark,
                    onToggle: _toggleTask,
                    onLongPress: (t) =>
                        _showInputSheet(isHabit: true, existingTask: t),
                    onAddGhost: (title, isHabit) => _addNewTask(title, isHabit),
                    onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllHabitsView()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // D. NOTES (Ideas)
                  NotesSection(
                    isDark: isDark,
                    onEditNote: (n) => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => NoteEditorSheet(existingNote: n),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOCAL WIDGETS ---

  Widget _buildTasksCard(List<MindTask> tasks, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                "TASKS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showInputSheet(isHabit: false),
                child: const Icon(Icons.add, size: 20, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty) ...[
            _buildGhostTask("Wash dishes", isDark),
            const SizedBox(height: 12),
            _buildGhostTask("Tidy up room", isDark),
          ] else
            ...tasks.map((task) => _buildRealTask(task, isDark)),
        ],
      ),
    );
  }

  Widget _buildGhostTask(String text, bool isDark) {
    return GestureDetector(
      onTap: () => _addNewTask(text, false), // Add on tap
      child: Opacity(
        opacity: 0.3,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTask(MindTask task, bool isDark) {
    return GestureDetector(
      onTap: () => _toggleTask(task),
      onLongPress: () => _showInputSheet(isHabit: false, existingTask: task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isDone ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.isDone
                      ? Colors.blue
                      : (isDark ? Colors.grey : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  color: task.isDone
                      ? Colors.white30
                      : (isDark ? Colors.white : Colors.black87),
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
