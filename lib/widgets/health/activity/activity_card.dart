import 'package:flutter/material.dart';
import '../../../../models/health_model.dart';
import 'routine_manager.dart';
import 'workout_logger.dart';
import 'exercise_models.dart';

class ActivityCard extends StatefulWidget {
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
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  int _currentExerciseIndex = 0;

  // MOCK DATA
  final List<ExerciseDetail> _activeExercises = [
    ExerciseDetail(
      name: "Bench Press",
      sets: [SetDetail(), SetDetail(), SetDetail()],
    ),
    ExerciseDetail(name: "Incline Fly", sets: [SetDetail(), SetDetail()]),
    ExerciseDetail(
      name: "Tricep Pushdown",
      sets: [SetDetail(), SetDetail(), SetDetail(), SetDetail()],
    ),
  ];

  final Set<int> _completedIndices = {};

  @override
  Widget build(BuildContext context) {
    final hasRoutine = widget.log.workoutName != null;

    return Container(
      // REDUCED PADDING: Content pushes closer to edges
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.log.isWorkoutDone
              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
              : [const Color(0xFFEF6C00), const Color(0xFFE65100)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (widget.log.isWorkoutDone ? Colors.green : Colors.orange)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !hasRoutine
          ? _buildSelectorState(context)
          : _buildPlayerState(context),
    );
  }

  Widget _buildSelectorState(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRoutineManager(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "No Routine",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Text(
            "Tap to Start",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerState(BuildContext context) {
    final currentExercise = _activeExercises[_currentExerciseIndex];
    final isFirst = _currentExerciseIndex == 0;
    final isLast = _currentExerciseIndex == _activeExercises.length - 1;
    final isExerciseDone = _completedIndices.contains(_currentExerciseIndex);
    final doneColor = const Color(0xFF69F0AE);

    return Column(
      children: [
        // 1. HEADER BUTTON (Top Edge)
        GestureDetector(
          onTap: () => _showRoutineManager(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.log.workoutName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ),

        // Pushes the content apart
        const Spacer(),

        // 2. MIDDLE: ARROWS + TEXT (Centered vertically in available space)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: isFirst
                  ? null
                  : () => setState(() => _currentExerciseIndex--),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isFirst ? Colors.white12 : Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExerciseDone)
                      Icon(Icons.check_circle, color: doneColor, size: 22),
                    if (isExerciseDone) const SizedBox(height: 2),
                    Text(
                      currentExercise.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isExerciseDone ? doneColor : Colors.white,
                        fontSize: 18, // Reduced font for better fit
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            IconButton(
              onPressed: isLast
                  ? null
                  : () => setState(() => _currentExerciseIndex++),
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: isLast ? Colors.white12 : Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),

        const Spacer(),

        // 3. BOTTOM: LOG BUTTON (Bottom Edge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: () => _showLogger(context, currentExercise),
            child: Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isExerciseDone ? Icons.check_circle : Icons.edit,
                    color: Colors.deepOrange,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExerciseDone ? "Logs" : "Log Sets",
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogger(BuildContext context, ExerciseDetail exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutLoggerSheet(
        exerciseName: exercise.name,
        targetSetCount: exercise.sets.length,
        onComplete: (done) {
          if (done) {
            setState(() {
              _completedIndices.add(_currentExerciseIndex);
              if (_currentExerciseIndex < _activeExercises.length - 1) {
                _currentExerciseIndex++;
              } else {
                if (_completedIndices.length == _activeExercises.length) {
                  widget.onWorkoutToggle(true);
                }
              }
            });
          }
        },
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
        builder: (_, scrollController) => RoutineManagerSheet(
          selectedRoutine: widget.log.workoutName,
          onSelected: (val) {
            widget.onRoutineChanged(val);
            setState(() {
              _currentExerciseIndex = 0;
              _completedIndices.clear();
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}
