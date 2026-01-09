import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/book_models.dart';

class AllHabitsView extends StatelessWidget {
  const AllHabitsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "All Habits",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: Center(
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('book_logs')
            .doc(dateKey)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState(isDark, "No habits found for today");
          }

          final log = BookDailyLog.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            DateTime.now(),
          );
          final habits = log.tasks.where((t) => t.isHabit).toList();

          if (habits.isEmpty) {
            return _buildEmptyState(isDark, "No habits tracked today");
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final habit = habits[index];

              // ✅ PROFESSIONAL CARD DESIGN
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    // Tapping the card opens edit, tapping the circle toggles
                    onTap: () => _showEditDialog(
                      context,
                      user!.uid,
                      dateKey,
                      log,
                      habit,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Toggle Checkbox
                          GestureDetector(
                            onTap: () =>
                                _toggleHabit(user!.uid, dateKey, log, habit),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: habit.isDone
                                    ? Colors.blue
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: habit.isDone
                                      ? Colors.blue
                                      : Colors.grey.shade600,
                                  width: 2,
                                ),
                              ),
                              child: habit.isDone
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    decoration: habit.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: Colors.blue,
                                    decorationThickness: 2,
                                  ),
                                ),
                                if (habit.streak > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${habit.streak} ",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.local_fire_department,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Edit Icon
                          Icon(
                            Icons.edit_outlined,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }

  void _toggleHabit(
    String uid,
    String dateKey,
    BookDailyLog log,
    MindTask habit,
  ) {
    final idx = log.tasks.indexWhere((t) => t.id == habit.id);
    if (idx != -1) {
      log.tasks[idx].isDone = !log.tasks[idx].isDone;
      if (log.tasks[idx].isDone)
        log.tasks[idx].streak += 1;
      else
        log.tasks[idx].streak = (log.tasks[idx].streak > 0)
            ? log.tasks[idx].streak - 1
            : 0;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('book_logs')
          .doc(dateKey)
          .update(log.toMap());
    }
  }

  void _showEditDialog(
    BuildContext context,
    String uid,
    String dateKey,
    BookDailyLog log,
    MindTask habit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: habit.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit Habit",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Habit Title",
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteHabit(context, uid, dateKey, log, habit);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Delete Habit",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.isNotEmpty) {
                      _updateHabitTitle(uid, dateKey, log, habit, ctrl.text);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateHabitTitle(
    String uid,
    String dateKey,
    BookDailyLog log,
    MindTask habit,
    String newTitle,
  ) {
    final idx = log.tasks.indexWhere((t) => t.id == habit.id);
    if (idx != -1) {
      log.tasks[idx].title = newTitle;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('book_logs')
          .doc(dateKey)
          .update(log.toMap());
    }
  }

  void _deleteHabit(
    BuildContext context,
    String uid,
    String dateKey,
    BookDailyLog log,
    MindTask habit,
  ) async {
    log.tasks.removeWhere((t) => t.id == habit.id);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('book_logs')
        .doc(dateKey)
        .update(log.toMap());

    // Future propagation logic (simplified for brevity here, assumed correct from previous)
    final futureLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('book_logs')
        .where('date', isGreaterThan: Timestamp.now())
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in futureLogs.docs) {
      final l = BookDailyLog.fromMap(doc.data(), DateTime.now());
      l.tasks.removeWhere((t) => t.id == habit.id);
      batch.update(doc.reference, {
        'tasks': l.tasks.map((t) => t.toMap()).toList(),
      });
    }
    await batch.commit();
  }
}
