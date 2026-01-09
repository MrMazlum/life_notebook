import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_models.dart';
import '../widgets/book/book_hero.dart';
import '../widgets/book/calendar_strip.dart';
import '../widgets/book/book_search_delegate.dart';
import '../widgets/book/book_summary_view.dart'; // NEW

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  DateTime _selectedDate = DateTime.now();
  late PageController _weekPageController;
  final int _initialPage = 1000;
  bool _forceInspectMode = false; // For viewing details of past days

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

  // --- LOGIC ---
  void _subscribeToDate(DateTime date) {
    _logSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    _logSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .doc(dateKey)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            if (mounted)
              setState(
                () =>
                    _currentLog = BookDailyLog.fromMap(snapshot.data()!, date),
              );
          } else {
            if (DateUtils.isSameDay(date, DateTime.now())) {
              _initializeDay(date); // Only auto-fill for today/future
            } else {
              if (mounted)
                setState(
                  () => _currentLog = BookDailyLog(date: date),
                ); // Empty for past if not exists
            }
          }
        });
  }

  Future<void> _initializeDay(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prevLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
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
              id: t.id,
              title: t.title,
              isHabit: true,
              isDone: false,
            ),
          )
          .toList();
    }
    if (mounted) {
      setState(
        () => _currentLog = BookDailyLog(date: date, tasks: inheritedHabits),
      );
      _saveToFirestore();
    }
  }

  void _saveToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('book_logs')
        .doc(dateKey)
        .set(_currentLog.toMap(), SetOptions(merge: true));
  }

  void _toggleTask(MindTask task) {
    setState(() => task.isDone = !task.isDone);
    _saveToFirestore();
  }

  void _addNewTask(String title, bool isHabit) {
    setState(
      () => _currentLog.tasks.add(
        MindTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          isHabit: isHabit,
          isDone: false,
        ),
      ),
    );
    _saveToFirestore();
  }

  void _deleteTask(MindTask task) {
    setState(() => _currentLog.tasks.removeWhere((t) => t.id == task.id));
    _saveToFirestore();
  }

  void _updateTaskTitle(MindTask task, String newTitle) {
    final idx = _currentLog.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() => _currentLog.tasks[idx].title = newTitle);
      _saveToFirestore();
    }
  }

  void _addNote(String title, String body) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newNote = MindNote(
      id: '',
      title: title,
      body: body,
      tag: "General",
      createdAt: DateTime.now(),
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .add(newNote.toMap());
  }

  void _updateNote(MindNote note, String t, String b) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .doc(note.id)
        .update({'title': t, 'body': b});
  }

  void _deleteNote(String id) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mind_notes')
        .doc(id)
        .delete();
  }

  void _updateBookProgress(
    String bookId,
    int pagesReadToday,
    int absolutePage,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update Log (Historical)
    setState(() {
      _currentLog.pagesRead += pagesReadToday;
      _currentLog.endPage = absolutePage;
    });
    _saveToFirestore();

    // Update Book (Global)
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

  // --- UI ACTIONS ---
  void _showNoteSheet({MindNote? existingNote}) {
    final tCtrl = TextEditingController(text: existingNote?.title);
    final bCtrl = TextEditingController(text: existingNote?.body);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Increased height and bottom padding for visibility
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
        ), // +40 for extra space
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            TextField(
              controller: bCtrl,
              maxLines: 5,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                hintText: "Start typing...",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (existingNote != null)
                  IconButton(
                    onPressed: () {
                      _deleteNote(existingNote.id);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (tCtrl.text.isNotEmpty) {
                      if (existingNote != null)
                        _updateNote(existingNote, tCtrl.text, bCtrl.text);
                      else
                        _addNote(tCtrl.text, bCtrl.text);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ... (Keep _showInputSheet, _showAddMenu same as before) ...
  // [Code omitted for brevity as it was correct in previous step, insert here]
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
                        _showNoteSheet();
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
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
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

  // ... (Date Helpers) ...
  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = date.subtract(Duration(days: date.weekday - 1));
    return _initialPage + (mondayDate.difference(mondayNow).inDays / 7).round();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _forceInspectMode = false;
    });
    _subscribeToDate(date);
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
          colorScheme: ColorScheme.dark(
            primary: Colors.blue,
            onPrimary: Colors.white,
            surface: const Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF1E1E1E),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      _onDateSelected(picked);
      _weekPageController.jumpToPage(_calculatePageForDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final themeColor = Colors.blue;

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isPast = _selectedDate.isBefore(DateUtils.dateOnly(DateTime.now()));

    // SWITCH VIEW: If past and not inspecting, show Summary
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
          CalendarStrip(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
            onBackToToday: _handleBackToToday,
            onPickerTap: _selectDateFromPicker,
            isDark: isDark,
            pageController: _weekPageController,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACTIVE BOOK (Simplified: Just reading status, no complex order)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('books')
                        .where('status', isEqualTo: 'reading')
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      Book? activeBook;
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final doc = snapshot.data!.docs.first;
                        activeBook = Book.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      }
                      return BookHero(
                        book: activeBook,
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
                  ),
                  const SizedBox(height: 24),
                  if (chores.isNotEmpty) _buildTasksCard(chores, isDark),
                  if (chores.isNotEmpty) const SizedBox(height: 24),
                  _buildHabitsSection(habits, isDark),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('mind_notes')
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final notes = (snapshot.data?.docs ?? [])
                          .map(
                            (d) => MindNote.fromMap(
                              d.data() as Map<String, dynamic>,
                              d.id,
                            ),
                          )
                          .toList();
                      return _buildNotesGrid(notes, isDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildEmptyFrame(
    String text,
    String btn,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              btn,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                "TASKS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => _showInputSheet(isHabit: false),
                child: Icon(Icons.add, size: 20, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map(
            (task) => GestureDetector(
              onTap: () => _toggleTask(task),
              onLongPress: () =>
                  _showInputSheet(isHabit: false, existingTask: task),
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
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          color: task.isDone
                              ? (isDark ? Colors.white30 : Colors.black38)
                              : (isDark ? Colors.white : Colors.black87),
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: isDark
                              ? Colors.white30
                              : Colors.black38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSection(List<MindTask> habits, bool isDark) {
    if (habits.isEmpty)
      return _buildEmptyFrame(
        "No habits tracked",
        "Add Habit",
        () => _showInputSheet(isHabit: true),
        isDark,
      );
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: habits.length + 1,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          if (i == habits.length)
            return GestureDetector(
              onTap: () => _showInputSheet(isHabit: true),
              child: Container(
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.blue),
              ),
            );
          return _buildHabitPill(habits[i], isDark);
        },
      ),
    );
  }

  Widget _buildHabitPill(MindTask habit, bool isDark) {
    final color = habit.isDone
        ? Colors.blue
        : (isDark ? Colors.white54 : Colors.grey);
    return GestureDetector(
      onTap: () => _toggleTask(habit),
      onLongPress: () => _showInputSheet(isHabit: true, existingTask: habit),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: habit.isDone
              ? Colors.blue.withOpacity(0.2)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          habit.title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNotesGrid(List<MindNote> notes, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        if (index == notes.length)
          return GestureDetector(
            onTap: () => _showNoteSheet(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 40, color: Colors.blue),
              ),
            ),
          );
        final note = notes[index];
        return GestureDetector(
          onLongPress: () => _showNoteSheet(existingNote: note),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2238) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.shade100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    note.body,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.blueGrey.shade200
                          : Colors.blueGrey.shade700,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
