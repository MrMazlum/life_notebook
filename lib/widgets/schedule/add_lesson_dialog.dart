import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lesson.dart';

class AddLessonDialog extends StatefulWidget {
  final Map<String, String> courseDatabase;
  final Function(Lesson) onAddLesson;
  final Future<void> Function(String, String) onUpdateGlobal;
  final DateTime selectedDate; // CHANGED: Now accepts DateTime

  const AddLessonDialog({
    super.key,
    required this.courseDatabase,
    required this.onAddLesson,
    required this.onUpdateGlobal,
    required this.selectedDate,
  });

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  final _roomController = TextEditingController();
  final _instructorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  late TextEditingController _courseNameController;

  int _selectedDuration = 60;
  bool _isLecture = true;
  bool _isInstructorLocked = false;
  bool _isRecurring = true;

  final List<int> _durations = [30, 45, 60, 90, 120, 180, 240];

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
      if (_isInstructorLocked) {
        setState(() {
          _instructorController.clear();
          _isInstructorLocked = false;
        });
      }
    }
  }

  Future<bool?> _showProfessionalConfirmDialog(
    BuildContext context,
    String course,
    String oldProf,
    String newProf,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 40, color: primaryColor),
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
                "Update instructor for '$course' globally?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Only This Class"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Update All",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
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
    if (existingKey.isNotEmpty && _isLecture) {
      final oldInstructor = widget.courseDatabase[existingKey]!;
      if (oldInstructor.isNotEmpty && oldInstructor != finalInstructor) {
        final shouldUpdateGlobal = await _showProfessionalConfirmDialog(
          context,
          finalCourseName,
          oldInstructor,
          finalInstructor,
        );
        performGlobalUpdate = shouldUpdateGlobal ?? false;
      }
    }

    if (performGlobalUpdate)
      widget.courseDatabase[finalCourseName] = finalInstructor;

    final parts = _startTimeController.text.split(':');
    final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);

    // NEW LOGIC: Calculate Specific Date string
    final dayName = DateFormat('EEEE').format(widget.selectedDate);
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    final newLesson = Lesson(
      userId: 'test_user',
      name: finalCourseName,
      room: _isLecture ? _roomController.text : '',
      instructor: _isLecture ? finalInstructor : '',
      description: _isLecture ? '' : _descriptionController.text,
      isLecture: _isLecture,
      isRecurring: _isRecurring,
      dayOfWeek: dayName,
      startTimeInMinutes: startMin,
      durationInMinutes: _selectedDuration,
      // CRITICAL FIX: If not recurring, lock it to this date.
      specificDate: _isRecurring ? '' : dateString,
    );

    try {
      if (performGlobalUpdate)
        widget.onUpdateGlobal(finalCourseName, finalInstructor);
      widget.onAddLesson(newLesson);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print("Error saving: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;
    final dayName = DateFormat('EEEE').format(widget.selectedDate);

    return AlertDialog(
      scrollable: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(
        child: Text('Add Event', style: TextStyle(fontWeight: FontWeight.bold)),
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
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '')
                  return const Iterable<String>.empty();
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
