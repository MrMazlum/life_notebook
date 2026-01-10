import 'package:flutter/material.dart';
import '../../models/health_model.dart';
import 'activity/exercise_models.dart';
import 'activity/routine_manager.dart';
import 'activity/routine_editor.dart';
import 'activity/set_editor.dart';

class WorkoutPlanView extends StatefulWidget {
  final HealthDailyLog log;
  final List<String> availableRoutines; // NEW: Accept the list
  final Function(String) onRoutineChanged;
  final Function() onLogUpdated;

  const WorkoutPlanView({
    super.key,
    required this.log,
    required this.availableRoutines, // NEW
    required this.onRoutineChanged,
    required this.onLogUpdated,
  });

  @override
  State<WorkoutPlanView> createState() => _WorkoutPlanViewState();
}

class _WorkoutPlanViewState extends State<WorkoutPlanView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = Colors.deepOrange;

    final hasRoutine = widget.log.workoutName != null;
    final exercises = widget.log.workoutLog;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER & ROUTINE SELECTOR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Target Routine",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showRoutineManager(context),
                    child: Row(
                      children: [
                        Text(
                          hasRoutine
                              ? widget.log.workoutName!
                              : "Select Routine",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: hasRoutine ? textColor : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ADD BUTTON
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: accentColor),
                  onPressed: () => _showExerciseSearch(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. EXERCISE LIST
          Expanded(
            child: exercises.isEmpty
                ? _buildEmptyState(isDark)
                : ReorderableListView.builder(
                    proxyDecorator: (child, index, animation) {
                      return Material(color: Colors.transparent, child: child);
                    },
                    itemCount: exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = exercises.removeAt(oldIndex);
                        exercises.insert(newIndex, item);
                      });
                      widget.onLogUpdated(); // Save reorder
                    },
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return _buildExerciseTile(
                        key: ValueKey("${exercise.name}_$index"),
                        exercise: exercise,
                        index: index,
                        isDark: isDark,
                        textColor: textColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile({
    required Key key,
    required ExerciseDetail exercise,
    required int index,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade100,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(
            "${index + 1}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.grey.shade700,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        subtitle: Text(
          "${exercise.sets.length} Sets Planned",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
              onPressed: () => _openSetEditor(context, exercise),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  widget.log.workoutLog.removeAt(index);
                });
                widget.onLogUpdated();
              },
            ),
            const Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_calendar_rounded,
            size: 60,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Exercises Planned",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select a routine or add exercises manually.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
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
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => RoutineManagerSheet(
          selectedRoutine: widget.log.workoutName,
          availableRoutines: widget.availableRoutines, // PASSED DOWN!
          onSelected: (name) {
            widget.onRoutineChanged(name);
            if (widget.log.workoutLog.isEmpty) {
              widget.log.workoutLog = _generateDefaultExercises(name);
            }
            widget.onLogUpdated();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

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
        onSelect: (name) {
          setState(() {
            widget.log.workoutLog.add(ExerciseDetail(name: name));
          });
          widget.onLogUpdated();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openSetEditor(BuildContext context, ExerciseDetail exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetEditorSheet(
        exerciseName: exercise.name,
        initialSets: exercise.sets,
        onSave: (updatedSets) {
          setState(() => exercise.sets = updatedSets);
          widget.onLogUpdated();
        },
      ),
    );
  }

  List<ExerciseDetail> _generateDefaultExercises(String routineName) {
    if (routineName.contains("Push")) {
      return [
        ExerciseDetail(name: "Bench Press"),
        ExerciseDetail(name: "Overhead Press"),
      ];
    } else if (routineName.contains("Pull")) {
      return [
        ExerciseDetail(name: "Deadlift"),
        ExerciseDetail(name: "Pull Ups"),
      ];
    } else {
      return [ExerciseDetail(name: "Squat"), ExerciseDetail(name: "Leg Press")];
    }
  }
}
