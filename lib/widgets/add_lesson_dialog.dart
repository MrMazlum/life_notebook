import 'package:flutter/material.dart';
import '../models/lesson.dart';

class AddLessonDialog extends StatefulWidget {
  final Map<String, String> courseDatabase;
  final List<Lesson> currentLessons;
  final Function(Lesson) onAddLesson;
  final Function(String name, String instructor) onSaveCourse;
  final Function(String name, bool deleteFromSchedule) onDeleteCourse;

  const AddLessonDialog({
    super.key,
    required this.courseDatabase,
    required this.currentLessons,
    required this.onAddLesson,
    required this.onSaveCourse,
    required this.onDeleteCourse,
  });

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  final _roomController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _newCourseNameController = TextEditingController();
  final _newInstructorController = TextEditingController();
  final _instructorDisplayController = TextEditingController();

  final List<int> _durationOptions = [30, 45, 60, 90, 120, 180];
  String? _selectedCourse;
  int _selectedDuration = 60;
  bool _isCreatingNewCourse = false;
  bool _isManageMode = false;

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      _startTimeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleDeleteRequest(String courseName) {
    bool isUsed = widget.currentLessons.any(
      (lesson) => lesson.name == courseName,
    );

    if (!isUsed) {
      widget.onDeleteCourse(courseName, false);
      setState(() {});
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("⚠ Course In Use"),
          content: Text(
            "The course '$courseName' is currently in your schedule.\n\nDo you want to delete the scheduled classes too?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDeleteCourse(courseName, false);
                setState(() {});
              },
              child: const Text("Keep Classes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDeleteCourse(courseName, true);
                setState(() {});
              },
              child: const Text(
                "Delete All",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _submit() {
    String finalCourseName = '';
    String finalInstructorName = '';

    if (_isCreatingNewCourse) {
      if (_newCourseNameController.text.isEmpty ||
          _newInstructorController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields!')),
        );
        return;
      }
      finalCourseName = _newCourseNameController.text;
      finalInstructorName = _newInstructorController.text;
      widget.onSaveCourse(finalCourseName, finalInstructorName);
    } else {
      if (_selectedCourse == null || _selectedCourse == '__NEW__') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a course!')),
        );
        return;
      }
      finalCourseName = _selectedCourse!;
      finalInstructorName = _instructorDisplayController.text;
    }

    if (_startTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time!')),
      );
      return;
    }

    final newLesson = Lesson(
      name: finalCourseName,
      room: _roomController.text.isEmpty ? 'Online' : _roomController.text,
      instructor: finalInstructorName,
      startTime: _startTimeController.text,
      durationMinutes: _selectedDuration,
    );

    widget.onAddLesson(newLesson);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Use colorScheme.primary for the vibrant color
    final vibrantColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isManageMode ? 'Manage Database' : 'Add New Class',
            style: TextStyle(color: textColor),
          ),
          IconButton(
            icon: Icon(
              _isManageMode ? Icons.close : Icons.settings,
              color: Colors.grey,
            ),
            onPressed: () => setState(() {
              _isManageMode = !_isManageMode;
              _selectedCourse = null;
              _isCreatingNewCourse = false;
            }),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _isManageMode
            ? SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: [
                    if (widget.courseDatabase.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Database empty.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...widget.courseDatabase.entries.map((entry) {
                      return ListTile(
                        title: Text(
                          entry.key,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          entry.value,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _handleDeleteRequest(entry.key),
                        ),
                      );
                    }),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.white,
                    isExpanded: true,
                    value: _selectedCourse,
                    items: [
                      ...widget.courseDatabase.keys.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: TextStyle(color: textColor)),
                        ),
                      ),
                      // FIX 2: Updated Text and Color
                      DropdownMenuItem(
                        value: '__NEW__',
                        child: Text(
                          '+ Create New Course...', // Cleaned up text
                          style: TextStyle(
                            color: vibrantColor,
                            fontWeight: FontWeight.bold,
                          ), // Uses vibrant color
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCourse = val;
                        if (val == '__NEW__') {
                          _isCreatingNewCourse = true;
                          _instructorDisplayController.clear();
                        } else {
                          _isCreatingNewCourse = false;
                          if (val != null)
                            _instructorDisplayController.text =
                                widget.courseDatabase[val]!;
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_isCreatingNewCourse) ...[
                    TextField(
                      controller: _newCourseNameController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'New Course Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  TextField(
                    controller: _isCreatingNewCourse
                        ? _newInstructorController
                        : _instructorDisplayController,
                    readOnly: !_isCreatingNewCourse,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Instructor',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _roomController,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startTimeController,
                          readOnly: true,
                          onTap: _selectTime,
                          style: TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            labelText: 'Start',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedDuration,
                          dropdownColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          items: _durationOptions
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    '$m min',
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDuration = v!),
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      actions: _isManageMode
          ? [
              TextButton(
                onPressed: () => setState(() => _isManageMode = false),
                child: const Text('Back to Form'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: vibrantColor,
                ), // Use vibrant color here too
                onPressed: _submit,
                child: Text(
                  'Add',
                  style: TextStyle(color: isDark ? Colors.black : Colors.white),
                ),
              ),
            ],
    );
  }
}
