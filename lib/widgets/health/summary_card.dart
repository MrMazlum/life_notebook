import 'package:flutter/material.dart';
import '../../models/health_model.dart';
import 'activity/exercise_models.dart';

class HealthSummaryView extends StatelessWidget {
  final HealthDailyLog log;
  final VoidCallback onInspectDetails;
  final VoidCallback onBackToToday;

  const HealthSummaryView({
    super.key,
    required this.log,
    required this.onInspectDetails,
    required this.onBackToToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    const accentColor = Colors.deepOrange;

    final isStepGoalMet = log.steps >= 10000;
    final hasWorkout = log.workoutName != null && log.workoutLog.isNotEmpty;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. HEADER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isStepGoalMet
                        ? [Colors.deepOrange, Colors.orange.shade800]
                        : [cardBg, cardBg],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isStepGoalMet
                          ? Icons.emoji_events
                          : Icons.bar_chart_rounded,
                      size: 48,
                      color: isStepGoalMet ? Colors.white : accentColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isStepGoalMet ? "Goal Crushed!" : "Daily Recap",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isStepGoalMet ? Colors.white : textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${log.steps} Steps • ${log.totalCalories} kcal",
                      style: TextStyle(
                        color: isStepGoalMet ? Colors.white70 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. WORKOUT LIST (Fixed Alignment)
              if (hasWorkout) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Workout Log",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    // FIX: This forces everything to the LEFT (Start)
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            log.workoutName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1),
                      ),
                      ...log.workoutLog.map(
                        (exercise) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            // FIX: Inner column also sticks to start
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: exercise.sets
                                    .map(
                                      (s) => Text(
                                        "${s.weight.toInt()}kg x ${s.reps}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // 3. ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBackToToday,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Back to Today",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onInspectDetails,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Edit Log",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
}
