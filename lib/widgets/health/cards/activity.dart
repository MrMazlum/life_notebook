/*
import 'package:flutter/material.dart';
import '../../../models/health_model.dart';

// --- MOCK DATABASE (Session Memory) ---
// This list persists as long as the app is open.
final List<String> _masterExerciseList = [
  "Bench Press",
  "Incline Dumbbell Press",
  "Push Ups",
  "Overhead Press",
  "Lateral Raises",
  "Tricep Extensions",
  "Skullcrushers",
  "Dips",
  "Pull Ups",
  "Lat Pulldown",
  "Barbell Row",
  "Dumbbell Row",
  "Face Pulls",
  "Bicep Curls",
  "Hammer Curls",
  "Preacher Curls",
  "Deadlift",
  "Squat",
  "Leg Press",
  "Leg Extension",
  "Hamstring Curl",
  "Lunges",
  "Bulgarian Split Squat",
  "Calf Raises",
  "Hip Thrust",
  "Treadmill Run",
  "Cycling",
  "Elliptical",
  "Jump Rope",
  "Burpees",
  "Plank",
  "Crunch",
  "Leg Raise",
  "Russian Twist",
];

// --- INTERNAL MODEL FOR EXERCISE DETAILS ---
class ExerciseDetail {
  String name;
  int sets;
  int reps;
  double weight;

  ExerciseDetail({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0.0,
  });
}

class ActivityCard extends StatelessWidget {
  final HealthDailyLog log;
  final Function(String?) onRoutineChanged;
  final Function(bool) onWorkoutToggle;
  final Function(int) onStepsChanged;
  final Function(double) onWeightChanged;

  const ActivityCard({
    super.key,
    required this.log,
    required this.onRoutineChanged,
    required this.onWorkoutToggle,
    required this.onStepsChanged,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        // 1. GYM CARD (Routine Picker)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: log.isWorkoutDone
                  ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                  : [const Color(0xFFEF6C00), const Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (log.isWorkoutDone ? Colors.green : Colors.orange)
                    .withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onWorkoutToggle(!log.isWorkoutDone),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    log.isWorkoutDone
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showRoutineManager(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Routine",
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.workoutName ?? "Select Routine",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. STEPS & WEIGHT ROW
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                context: context,
                icon: Icons.directions_walk,
                title: "Steps",
                value: "${log.steps}",
                unit: "steps",
                color: Colors.orange,
                bg: cardColor,
                text: textColor,
                onSave: (val) => onStepsChanged(int.parse(val)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildValueCard(
                context: context,
                icon: Icons.monitor_weight,
                title: "Weight",
                value: "${log.weight}",
                unit: "kg",
                color: Colors.deepPurple,
                bg: cardColor,
                text: textColor,
                isDouble: true,
                onSave: (val) => onWeightChanged(double.parse(val)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    required Color bg,
    required Color text,
    required Function(String) onSave,
    bool isDouble = false,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () =>
            _showEditDialog(context, title, value, unit, onSave, isDouble),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: text,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentVal,
    String unit,
    Function(String) onSave,
    bool isDouble,
  ) {
    final controller = TextEditingController(text: currentVal);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update $title",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
              autofocus: true,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                suffixText: unit,
                hintText: "0",
                border: InputBorder.none,
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) onSave(controller.text);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) {
          return RoutineManagerSheet(
            selectedRoutine: log.workoutName,
            onSelected: (val) {
              onRoutineChanged(val);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}

// --- ROUTINE MANAGER ---
class RoutineManagerSheet extends StatefulWidget {
  final String? selectedRoutine;
  final Function(String) onSelected;

  const RoutineManagerSheet({
    super.key,
    required this.selectedRoutine,
    required this.onSelected,
  });

  @override
  State<RoutineManagerSheet> createState() => _RoutineManagerSheetState();
}

class _RoutineManagerSheetState extends State<RoutineManagerSheet> {
  String _mode = 'list';
  final List<String> _userRoutines = [
    "Push Day A",
    "Pull Day A",
    "Legs",
    "Full Body",
  ];

  // EDITOR STATE
  final TextEditingController _editorNameCtrl = TextEditingController();
  final List<ExerciseDetail> _currentExercises = []; // Changed to Object list

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_mode == 'editor')
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24),
                  onPressed: () => setState(() => _mode = 'list'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              Text(
                _mode == 'list' ? "My Routines" : "Edit Routine",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (_mode == 'list')
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.deepOrange,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _mode = 'editor';
                      _editorNameCtrl.text = "New Routine";
                      _currentExercises.clear();
                    });
                  },
                )
              else
                TextButton(
                  onPressed: () {
                    if (_editorNameCtrl.text.isNotEmpty) {
                      // Logic to save would go here
                      if (!_userRoutines.contains(_editorNameCtrl.text)) {
                        _userRoutines.add(_editorNameCtrl.text);
                      }
                    }
                    setState(() => _mode = 'list');
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Expanded(
            child: _mode == 'list'
                ? _buildList(textColor, isDark)
                : _buildEditor(textColor, isDark),
          ),
        ],
      ),
    );
  }

  // --- POLISHED LIST VIEW ---
  Widget _buildList(Color textColor, bool isDark) {
    return ListView.separated(
      itemCount: _userRoutines.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final routine = _userRoutines[index];
        final isSelected = routine == widget.selectedRoutine;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.deepOrange, width: 1.5)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.deepOrange,
                size: 20,
              ),
            ),
            title: Text(
              routine,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            subtitle: const Text(
              "Tap to select",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // FIX: Vertical Alignment
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _mode = 'editor';
                      _editorNameCtrl.text = routine;
                      _currentExercises.clear();
                      // Mock loading saved exercises
                      _currentExercises.add(
                        ExerciseDetail(name: "Bench Press"),
                      );
                      _currentExercises.add(
                        ExerciseDetail(name: "Tricep Extensions", sets: 4),
                      );
                    });
                  },
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else
                  IconButton(
                    icon: const Icon(
                      Icons.circle_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                    onPressed: () => widget.onSelected(routine),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DETAILED EDITOR VIEW ---
  Widget _buildEditor(Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _editorNameCtrl,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          decoration: const InputDecoration(
            labelText: "Routine Name",
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Exercises (${_currentExercises.length})",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            TextButton.icon(
              onPressed: () => _showExerciseSearch(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add"),
              style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
            ),
          ],
        ),

        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _currentExercises.removeAt(oldIndex);
                _currentExercises.insert(newIndex, item);
              });
            },
            children: [
              for (int i = 0; i < _currentExercises.length; i++)
                _buildExerciseTile(i, _currentExercises[i], textColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseTile(
    int index,
    ExerciseDetail exercise,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      key: ValueKey(exercise.name + index.toString()),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(
          exercise.name,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${exercise.sets} Sets • ${exercise.reps} Reps • ${exercise.weight}kg",
          style: TextStyle(
            color: Colors.deepOrange.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SETTINGS BUTTON (Blue Area Logic)
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () => _showSetDetailsDialog(index, exercise),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () =>
                  setState(() => _currentExercises.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXERCISE SEARCH SHEET ---
  void _showExerciseSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ExerciseSearchSheet(
        onSelect: (exerciseName) {
          setState(
            () => _currentExercises.add(ExerciseDetail(name: exerciseName)),
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // --- SET DETAILS DIALOG ---
  void _showSetDetailsDialog(int index, ExerciseDetail exercise) {
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: exercise.reps.toString());
    final weightCtrl = TextEditingController(text: exercise.weight.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Target Goals",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogInput("Sets", setsCtrl, isDark),
            const SizedBox(height: 12),
            _buildDialogInput("Reps", repsCtrl, isDark),
            const SizedBox(height: 12),
            _buildDialogInput("Weight (kg)", weightCtrl, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentExercises[index].sets =
                    int.tryParse(setsCtrl.text) ?? 3;
                _currentExercises[index].reps =
                    int.tryParse(repsCtrl.text) ?? 10;
                _currentExercises[index].weight =
                    double.tryParse(weightCtrl.text) ?? 0.0;
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInput(
    String label,
    TextEditingController ctrl,
    bool isDark,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepOrange),
        ),
      ),
    );
  }
}

// --- SMART SEARCH SHEET ---
class ExerciseSearchSheet extends StatefulWidget {
  final Function(String) onSelect;
  const ExerciseSearchSheet({super.key, required this.onSelect});

  @override
  State<ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<ExerciseSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _filteredList = _masterExerciseList;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _masterExerciseList;
      } else {
        _filteredList = _masterExerciseList
            .where((ex) => ex.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? Colors.black26 : Colors.grey.shade100;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add Exercise",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Search (e.g. Bench...)",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: _filteredList.isEmpty
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // LOGIC FIX: MEMORY UPDATE
                        // This ensures Arnold Press is saved for future searches in this session
                        _masterExerciseList.add(_searchCtrl.text);
                        widget.onSelect(_searchCtrl.text);
                      },
                      icon: const Icon(Icons.add),
                      label: Text("Create '${_searchCtrl.text}'"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredList.length,
                    separatorBuilder: (ctx, i) =>
                        Divider(color: Colors.grey.withOpacity(0.1)),
                    itemBuilder: (ctx, i) {
                      return ListTile(
                        title: Text(
                          _filteredList[i],
                          style: TextStyle(color: textColor),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.deepOrange,
                        ),
                        onTap: () => widget.onSelect(_filteredList[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
*/
