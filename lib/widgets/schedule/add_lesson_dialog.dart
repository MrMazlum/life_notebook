import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/lesson.dart';

class AddLessonDialog extends StatefulWidget {
  final Map<String, String> courseDatabase;
  final Function(Lesson) onAddLesson;
  final Future<void> Function(String, String) onUpdateGlobal;
  final DateTime selectedDate;
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

  // Category State
  String _selectedCategory = 'general';
  Color _selectedColor = Colors.grey;

  final List<int> _durations = [30, 45, 60, 90, 120, 180, 240];

  // Categories Definition
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'gym',
      'label': 'Gym',
      'icon': Icons.fitness_center,
      'color': Colors.deepOrange,
    },
    {
      'id': 'food',
      'label': 'Food',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'id': 'read',
      'label': 'Read',
      'icon': Icons.menu_book,
      'color': Colors.blue,
    },
    {
      'id': 'coffee',
      'label': 'Coffee',
      'icon': Icons.coffee,
      'color': Colors.brown,
    },
    {
      'id': 'work',
      'label': 'Work',
      'icon': Icons.work,
      'color': Colors.blueGrey,
    },
    {
      'id': 'general',
      'label': 'Other',
      'icon': Icons.event,
      'color': Colors.grey,
    },
  ];

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
    _courseNameController = TextEditingController(text: edit?.name ?? '');

    // Format start time
    String initialTimeStr = '';
    if (edit != null) {
      final h = edit.startTimeInMinutes ~/ 60;
      final m = edit.startTimeInMinutes % 60;
      initialTimeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    _startTimeController = TextEditingController(text: initialTimeStr);

    // 2. Pre-fill State
    if (edit != null) {
      _isLecture = edit.isLecture;
      _isRecurring = edit.isRecurring;
      _selectedDuration = edit.durationInMinutes;
      _selectedCategory = edit.category;
      _selectedColor = Color(edit.colorValue); // Restore color

      if (edit.instructor.isNotEmpty) {
        _isInstructorLocked = true;
      }
    } else {
      // Default for new task
      _selectedColor = _categories.last['color'];
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

  // --- RESTORED: The "Update All?" Dialog ---
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
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
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
                  textAlign: TextAlign.center,
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
                      Expanded(
                        child: Column(
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
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Column(
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
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
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
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          "Only This Class",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // --- 1. HANDLE COURSE NAME & INSTRUCTOR LOGIC ---
    String finalCourseName = _toTitleCase(_courseNameController.text.trim());
    final existingKey = widget.courseDatabase.keys.firstWhere(
      (k) => k.toLowerCase() == finalCourseName.toLowerCase(),
      orElse: () => '',
    );
    if (existingKey.isNotEmpty) finalCourseName = existingKey;

    String finalInstructor = _toTitleCase(_instructorController.text.trim());
    bool performGlobalUpdate = false;

    // Only check instructor logic if it is a Lecture/Class
    if (existingKey.isNotEmpty && _isLecture) {
      final oldInstructor = widget.courseDatabase[existingKey]!;
      if (oldInstructor.isNotEmpty && oldInstructor != finalInstructor) {
        final result = await _showProfessionalConfirmDialog(
          context,
          finalCourseName,
          oldInstructor,
          finalInstructor,
        );
        if (result == null) return; // Cancelled
        performGlobalUpdate = result;
      }
    }

    // Update local map for immediate feedback
    if (performGlobalUpdate) {
      widget.courseDatabase[finalCourseName] = finalInstructor;
    }

    // --- 2. PREPARE DATA ---
    final parts = _startTimeController.text.split(':');
    final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final dayName = DateFormat('EEEE').format(widget.selectedDate);
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    // Determine Colors and Category
    final finalColor = _isLecture
        ? 0xFF7C4DFF
        : _selectedColor.value; // Purple if Class, Custom if Task
    final finalCat = _isLecture ? 'class' : _selectedCategory;

    final newLesson = Lesson(
      id: widget.lessonToEdit?.id,
      userId: user.uid,
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
      category: finalCat, // Saved Category
      colorValue: finalColor, // Saved Color
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
    final accentColor = isDark
        ? Colors.deepPurpleAccent
        : Theme.of(context).primaryColor;
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TOGGLE ROW ---
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("🎓 Class")),
                    selected: _isLecture,
                    onSelected: (val) => setState(() => _isLecture = true),
                    selectedColor: Colors.deepPurpleAccent.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: _isLecture ? Colors.deepPurpleAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: _isLecture
                          ? Colors.deepPurpleAccent
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("📝 Task")),
                    selected: !_isLecture,
                    onSelected: (val) => setState(() => _isLecture = false),
                    selectedColor: _selectedColor.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: !_isLecture ? _selectedColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: !_isLecture
                          ? _selectedColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- CATEGORY SELECTOR (Only for Task) ---
            if (!_isLecture)
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['id'];
                          _selectedColor = cat['color'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat['color']
                              : (isDark ? Colors.black26 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: cat['color'], width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (!_isLecture) const SizedBox(height: 16),

            // --- DAY DISPLAY ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
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

            // --- COURSE NAME (Autocomplete) ---
            Autocomplete<String>(
              initialValue: TextEditingValue(
                text: widget.lessonToEdit?.name ?? '',
              ),
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
                        labelText: _isLecture ? 'Course Name' : 'Title',
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

            // --- LECTURE FIELDS vs TASK FIELDS ---
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

            // --- TIME & DURATION ---
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

            // --- RECURRING & DELETE ---
            CheckboxListTile(
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
