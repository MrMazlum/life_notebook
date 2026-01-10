import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../../models/lesson.dart'; // Import Lesson model
import '../schedule/add_lesson_dialog.dart'; // Import your Dialog

class ScheduleCard extends StatelessWidget {
  final VoidCallback onNavigate;
  const ScheduleCard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final DashboardModel _model = DashboardModel();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = Colors.deepPurple;

    return StreamBuilder<Map<String, dynamic>>(
      stream: _model.getUpNext(),
      builder: (context, snapshot) {
        String time = "--:--";
        String endTime = "";
        String title = "No Events";
        String room = "Free";

        if (snapshot.hasData) {
          final data = snapshot.data!;
          time = data['startTime'] ?? "--:--";
          endTime = data['endTime'] ?? "";
          title = data['title'] ?? "No Events";
          room = data['room'] ?? "Free";
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border(bottom: BorderSide(color: accent, width: 4)),
            boxShadow: [
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        "UP NEXT",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  _buildArrowButton(accent, onNavigate),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        endTime,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white10 : Colors.grey[300],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              room,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionBtn(
                    context,
                    Icons.check_circle_outline,
                    "Add Task",
                    () => _showProfessionalSheet(
                      context,
                      "New Task",
                      "Task Name",
                      _model.addTask,
                    ),
                  ),
                  _buildActionBtn(
                    context,
                    Icons.event_note,
                    "Add Event",
                    () => _showLessonDialog(
                      context,
                      _model,
                    ), // Opens your professional dialog
                  ),
                  _buildActionBtn(
                    context,
                    Icons.lightbulb_outline,
                    "Idea",
                    () => _showProfessionalSheet(
                      context,
                      "Quick Idea",
                      "What's on your mind?",
                      _model.addIdea,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArrowButton(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. PROFESSIONAL TASK/IDEA SHEET ---
  void _showProfessionalSheet(
    BuildContext context,
    String title,
    String hint,
    Function(String) onSave,
  ) {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Dark professional background
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    onSave(controller.text);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
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
      ),
    );
  }

  // --- 2. INTEGRATE YOUR ADD LESSON DIALOG ---
  void _showLessonDialog(BuildContext context, DashboardModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AddLessonDialog(
        courseDatabase: {}, // Empty for quick add, or populate if you wish
        selectedDate: DateTime.now(), // Defaults to Today
        onAddLesson: (Lesson lesson) {
          model.addLesson(lesson);
        },
        onUpdateGlobal: model.updateGlobalInstructor,
      ),
    );
  }
}
