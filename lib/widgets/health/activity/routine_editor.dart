import 'package:flutter/material.dart';
import 'exercise_models.dart';
import 'set_editor.dart';

class RoutineEditorSheet extends StatefulWidget {
  final String? initialName;
  // Callback now returns Name AND the Exercises for that routine
  final Function(String, List<ExerciseDetail>) onSave;

  const RoutineEditorSheet({super.key, this.initialName, required this.onSave});

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  late TextEditingController _nameCtrl;
  final List<ExerciseDetail> _exercises = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? "");

    // If we are editing an existing routine, in a real DB app we would fetch
    // the existing exercises for this routine here.
    // For this version, if it's new, we start empty.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputColor = isDark ? Colors.black26 : Colors.grey.shade100;

    // Force height to 90% of screen for full editor feel
    final height = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Save Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialName == null ? "New Routine" : "Edit Routine",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: _handleSave,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Routine Name Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _nameCtrl,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: "Routine Name",
                labelStyle: TextStyle(color: Colors.grey),
                hintText: "e.g. Chest & Tris",
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Exercise List Header
          Text(
            "Exercises (${_exercises.length})",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Reorderable List
          Expanded(
            child: _exercises.isEmpty
                ? Center(
                    child: Text(
                      "No exercises yet.\nTap below to add.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = _exercises.removeAt(oldIndex);
                        _exercises.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < _exercises.length; i++)
                        _buildExerciseTile(i, _exercises[i], textColor, isDark),
                    ],
                  ),
          ),

          // "Add Exercise" Button (Pinned Bottom)
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _showSmartSearch(context),
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Exercise",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inputColor,
                  foregroundColor: Colors.deepOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(
    int index,
    ExerciseDetail exercise,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      key: ValueKey(
        "${exercise.name}_$index",
      ), // Unique Key for ReorderableListView
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.drag_indicator, color: Colors.grey.shade600),
        title: Text(
          exercise.name,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${exercise.sets.length} Sets",
          style: TextStyle(
            color: Colors.deepOrange.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Sets Button
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () => _openSetEditor(exercise),
            ),
            // Remove Button
            IconButton(
              icon: Icon(
                Icons.close,
                size: 20,
                color: Colors.red.withOpacity(0.7),
              ),
              onPressed: () => setState(() => _exercises.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please name your routine")));
      return;
    }
    // Pass back both name and the list of exercises
    widget.onSave(_nameCtrl.text.trim(), _exercises);
  }

  void _openSetEditor(ExerciseDetail exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetEditorSheet(
        exerciseName: exercise.name,
        initialSets: exercise.sets,
        onSave: (updatedSets) => setState(() => exercise.sets = updatedSets),
      ),
    );
  }

  void _showSmartSearch(BuildContext context) {
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
        onSelect: (name) {
          setState(() {
            _exercises.add(ExerciseDetail(name: name));
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// --- SMART SEARCH SHEET (Part of Routine Editor) ---
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
    // Load from master list
    _filteredList = masterExerciseList;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = masterExerciseList;
      } else {
        _filteredList = masterExerciseList
            .where((ex) => ex.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
              hintText: "Search...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: _filteredList.isEmpty
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Logic to create a new custom exercise locally
                        masterExerciseList.add(_searchCtrl.text);
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
