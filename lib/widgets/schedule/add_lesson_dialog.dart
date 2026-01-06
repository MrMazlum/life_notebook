import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lesson.dart';

class AddLessonDialog extends StatefulWidget {
  final Map<String, String> courseDatabase;
  final Function(Lesson) onAddLesson;
  final Future<void> Function(String, String) onUpdateGlobal;
  final DateTime selectedDate;
  // Optional parameters for Editing
  final Lesson? lessonToEdit;
  final Function(String)? onDelete;

  const AddLessonDialog({
    super.key,
    required this.courseDatabase,
    required this.onAddLesson,
    required this.onUpdateGlobal,
    required this.selectedDate,
    this.lessonToEdit,
    this.onDelete,
  });

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  // Controllers
  late TextEditingController _roomController;
  late TextEditingController _instructorController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _courseNameController;

  int _selectedDuration = 60;
  bool _isLecture = true;
  bool _isInstructorLocked = false;
  bool _isRecurring = true;

  final List<int> _durations = [30, 45, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    final edit = widget.lessonToEdit;

    // 1. Pre-fill Controllers
    _roomController = TextEditingController(text: edit?.room ?? '');
    _instructorController = TextEditingController(text: edit?.instructor ?? '');
    _descriptionController = TextEditingController(
      text: edit?.description ?? '',
    );

    // Format start time for the controller
    String initialTimeStr = '';
    if (edit != null) {
      final h = edit.startTimeInMinutes ~/ 60;
      final m = edit.startTimeInMinutes % 60;
      initialTimeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    _startTimeController = TextEditingController(text: initialTimeStr);
    _courseNameController = TextEditingController(text: edit?.name ?? '');

    // 2. Pre-fill State booleans
    if (edit != null) {
      _isLecture = edit.isLecture;
      _isRecurring = edit.isRecurring;
      _selectedDuration = edit.durationInMinutes;
      if (edit.instructor.isNotEmpty) {
        _isInstructorLocked = true;
      }
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _selectTime() async {
    TimeOfDay initial = TimeOfDay.now();
    if (_startTimeController.text.isNotEmpty) {
      try {
        final parts = _startTimeController.text.split(':');
        initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      setState(() {
        _startTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onCourseNameChanged(String value) {
    final key = widget.courseDatabase.keys.firstWhere(
      (k) => k.toLowerCase() == value.toLowerCase(),
      orElse: () => '',
    );

    if (key.isNotEmpty) {
      if (_instructorController.text != widget.courseDatabase[key]!) {
        setState(() {
          _instructorController.text = widget.courseDatabase[key]!;
          _isInstructorLocked = true;
        });
      }
    } else {
      if (_isInstructorLocked && !_isLecture) {
        setState(() => _isInstructorLocked = false);
      }
    }
  }

  // UPDATED: Added Cancel Button logic
  Future<bool?> _showProfessionalConfirmDialog(
    BuildContext context,
    String course,
    String oldProf,
    String newProf,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final highlightColor = isDark ? Colors.deepPurpleAccent : primaryColor;

    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlightColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, size: 32, color: highlightColor),
              ),
              const SizedBox(height: 16),
              Text(
                "Professor Changed",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Update instructor for '$course'?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              // Comparison Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "OLD",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          oldProf,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Column(
                      children: [
                        const Text(
                          "NEW",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          newProf,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        "Only This Class",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: highlightColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Update All",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ADDED: Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(ctx, null), // null means cancel
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_courseNameController.text.isEmpty ||
        _startTimeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing Name or Time')));
      return;
    }

    String finalCourseName = _toTitleCase(_courseNameController.text.trim());
    final existingKey = widget.courseDatabase.keys.firstWhere(
      (k) => k.toLowerCase() == finalCourseName.toLowerCase(),
      orElse: () => '',
    );
    if (existingKey.isNotEmpty) finalCourseName = existingKey;

    String finalInstructor = _toTitleCase(_instructorController.text.trim());

    bool performGlobalUpdate = false;

    // Check for professor change
    if (existingKey.isNotEmpty && _isLecture) {
      final oldInstructor = widget.courseDatabase[existingKey]!;
      if (oldInstructor.isNotEmpty && oldInstructor != finalInstructor) {
        final result = await _showProfessionalConfirmDialog(
          context,
          finalCourseName,
          oldInstructor,
          finalInstructor,
        );

        if (result == null) {
          // User clicked Cancel, abort save
          return;
        }
        performGlobalUpdate = result;
      }
    }

    if (performGlobalUpdate) {
      widget.courseDatabase[finalCourseName] = finalInstructor;
    }

    final parts = _startTimeController.text.split(':');
    final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);

    final dayName = DateFormat('EEEE').format(widget.selectedDate);
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    final newLesson = Lesson(
      id: widget.lessonToEdit?.id,
      userId: 'test_user',
      name: finalCourseName,
      room: _isLecture ? _roomController.text : '',
      instructor: _isLecture ? finalInstructor : '',
      description: _isLecture ? '' : _descriptionController.text,
      isLecture: _isLecture,
      isRecurring: _isRecurring,
      dayOfWeek: widget.lessonToEdit?.dayOfWeek ?? dayName,
      startTimeInMinutes: startMin,
      durationInMinutes: _selectedDuration,
      specificDate: _isRecurring ? '' : dateString,
      excludeDates: widget.lessonToEdit?.excludeDates ?? [],
    );

    try {
      if (performGlobalUpdate) {
        await widget.onUpdateGlobal(finalCourseName, finalInstructor);
      }
      widget.onAddLesson(newLesson);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error saving: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.lessonToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;
    final dayName = DateFormat('EEEE').format(widget.selectedDate);

    return AlertDialog(
      scrollable: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Center(
        child: Text(
          isEditing ? 'Edit Event' : 'Add Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("🎓 Class")),
                    selected: _isLecture,
                    onSelected: (val) => setState(() => _isLecture = true),
                    selectedColor: accentColor.withOpacity(0.3),
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: _isLecture
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white70 : Colors.black54),
                      fontWeight: _isLecture
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: _isLecture
                          ? accentColor
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("📝 Task")),
                    selected: !_isLecture,
                    onSelected: (val) => setState(() => _isLecture = false),
                    selectedColor: accentColor.withOpacity(0.3),
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: !_isLecture
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white70 : Colors.black54),
                      fontWeight: !_isLecture
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: !_isLecture
                          ? accentColor
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
              child: Text(
                dayName,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              initialValue: TextEditingValue(
                text: widget.lessonToEdit?.name ?? '',
              ),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return widget.courseDatabase.keys.where(
                  (String option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) => _onCourseNameChanged(selection),
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    _courseNameController = controller;
                    if (widget.lessonToEdit != null &&
                        controller.text.isEmpty &&
                        _courseNameController.text.isEmpty) {
                      controller.text = widget.lessonToEdit!.name;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: _onCourseNameChanged,
                      decoration: InputDecoration(
                        labelText: _isLecture ? 'Course Name' : 'Activity Name',
                        hintText: 'e.g. Math or Gym',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 12),
            if (_isLecture) ...[
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructorController,
                readOnly: _isInstructorLocked,
                decoration: InputDecoration(
                  labelText: 'Instructor',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  filled: _isInstructorLocked,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  suffixIcon: _isInstructorLocked
                      ? IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _isInstructorLocked = false),
                        )
                      : null,
                ),
              ),
            ] else ...[
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: const InputDecoration(
                      labelText: 'Start',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedDuration,
                    items: _durations
                        .map(
                          (m) =>
                              DropdownMenuItem(value: m, child: Text('$m m')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDuration = v!),
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  side: BorderSide(
                    color: isDark ? Colors.white70 : Colors.grey,
                    width: 2,
                  ),
                  checkColor: MaterialStateProperty.all(Colors.white),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Recurring Event",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "Repeat every week",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _isRecurring,
                activeColor: accentColor,
                onChanged: (val) => setState(() => _isRecurring = val ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            if (isEditing && widget.onDelete != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              TextButton.icon(
                onPressed: () {
                  widget.onDelete!(widget.lessonToEdit!.id!);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  "Delete Event",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(isEditing ? 'Save Changes' : 'Save'),
        ),
      ],
    );
  }
}
