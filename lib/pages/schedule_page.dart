import 'package:flutter/material.dart';
import '../models/lesson.dart'; 

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // 1. DATABASE
  final Map<String, String> _courseDatabase = {
    'Linear Algebra': 'Dr. Alan Turing',
    'Physics II': 'Dr. Marie Curie',
    'History': 'Mr. Herodotus',
    'English': 'Mr. Shakespeare',
    'Flutter Development': 'Mr. Mazlum',
    'Gym / Sports': 'Coach Arnold',
    'Lunch Break': '-',
  };

  final List<int> _durationOptions = [30, 45, 60, 90, 120, 180];

  List<Lesson> myLessons = [
    Lesson(
      name: 'Linear Algebra',
      startTime: '09:00',
      durationMinutes: 90,
      room: 'B-204',
      instructor: 'Dr. Alan Turing',
    ),
  ];

  final _roomController = TextEditingController();
  final _startTimeController = TextEditingController();
  
  String? _selectedCourse;
  String? _autoSelectedInstructor;
  int _selectedDuration = 60;

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        // Ensures the picker respects the dark/light theme
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String formattedTime = 
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  void _showAddLessonDialog() {
    _selectedCourse = null;
    _autoSelectedInstructor = null;
    _roomController.clear();
    _startTimeController.clear();
    _selectedDuration = 60;

    showDialog(
      context: context,
      builder: (context) {
        // Use the current page theme color
        final themeColor = Theme.of(context).primaryColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text('Add New Class', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCourse,
                      items: _courseDatabase.keys.map((String course) {
                        return DropdownMenuItem<String>(
                          value: course,
                          child: Text(course, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() {
                          _selectedCourse = newValue;
                          if (newValue != null) {
                            _autoSelectedInstructor = _courseDatabase[newValue];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: TextEditingController(text: _autoSelectedInstructor),
                      readOnly: true,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Instructor (Auto-Filled)',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _roomController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Room', 
                        hintText: 'Ex: B-101',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _startTimeController,
                            readOnly: true,
                            onTap: () => _selectTime(_startTimeController),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Start Time', 
                              hintText: '00:00',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              prefixIcon: Icon(Icons.timer),
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedDuration,
                            items: _durationOptions.map((int minutes) {
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text('$minutes min', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateDialog(() {
                                _selectedDuration = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  onPressed: () {
                    // 1. VALIDATION
                    if (_startTimeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start time! ⚠️')));
                      return;
                    }
                    if (_selectedCourse == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a course! ⚠️')));
                      return;
                    }

                    // 2. CONFLICT CHECK LOGIC
                    final newStartParts = _startTimeController.text.split(':');
                    final newStartMin = int.parse(newStartParts[0]) * 60 + int.parse(newStartParts[1]);
                    final newEndMin = newStartMin + _selectedDuration;

                    bool hasConflict = false;

                    for (var lesson in myLessons) {
                      final existingStartParts = lesson.startTime.split(':');
                      final existingStartMin = int.parse(existingStartParts[0]) * 60 + int.parse(existingStartParts[1]);
                      final existingEndMin = existingStartMin + lesson.durationMinutes;

                      if (newStartMin < existingEndMin && newEndMin > existingStartMin) {
                        hasConflict = true;
                        break;
                      }
                    }

                    if (hasConflict) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Conflict detected! You have another class at this time! ⛔'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 3. ADD LESSON
                    setState(() {
                      myLessons.add(Lesson(
                          name: _selectedCourse!,
                          room: _roomController.text.isEmpty ? 'Online' : _roomController.text,
                          instructor: _autoSelectedInstructor ?? 'TBD',
                          startTime: _startTimeController.text,
                          durationMinutes: _selectedDuration,
                        ));
                      myLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLesson(int index) {
    setState(() {
      myLessons.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This color comes from the Theme set in main.dart (Purple for index 4)
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Transparent background so it shows the main.dart background
      backgroundColor: Colors.transparent,
      
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLessonDialog, 
        backgroundColor: primaryColor, 
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Text(
              'Monday, October 24',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: myLessons.isEmpty 
              ? Center(child: Text("No classes today! 🎉", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
              : ListView.builder(
                itemCount: myLessons.length,
                itemBuilder: (context, index) {
                  final lesson = myLessons[index];
                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) => _deleteLesson(index),
                    background: Container(
                      color: Colors.red, 
                      alignment: Alignment.centerRight, 
                      padding: const EdgeInsets.only(right: 20), 
                      child: const Icon(Icons.delete, color: Colors.white)
                    ),
                    child: ClassCard(lesson: lesson),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassCard extends StatelessWidget {
  final Lesson lesson;
  const ClassCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final String endTime = lesson.getEndTimeString();
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors for text/icons
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = Colors.grey;
    final Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Timeline - Time
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lesson.startTime,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
                Text("|", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                Text(
                  endTime,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          // Timeline - Line & Dot
          Column(
            children: [
              Container(height: 50, width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 12, width: 12,
                decoration: BoxDecoration(
                  color: primaryColor, 
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: isDark ? const Color(0xFF121212) : Colors.white),
                ),
              ),
              Container(height: 50, width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ],
          ),
          // Content Card
          Expanded(
            child: Card(
              color: cardBgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(lesson.room, style: TextStyle(fontSize: 14, color: subTextColor)),
                        const Spacer(),
                        Icon(Icons.person, size: 14, color: subTextColor),
                        const SizedBox(width: 4),
                        Text(lesson.instructor, style: TextStyle(fontSize: 14, color: subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${lesson.durationMinutes} min",
                        style: TextStyle(fontSize: 10, color: primaryColor),
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
}