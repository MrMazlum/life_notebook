import 'package:flutter/material.dart';
import '../../models/health_model.dart';

class HealthList extends StatelessWidget {
  final HealthDailyLog log;
  final Function(bool) onWorkoutToggle;

  const HealthList({
    super.key,
    required this.log,
    required this.onWorkoutToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // GYM HERO CARD
          GestureDetector(
            onTap: () => onWorkoutToggle(!log.isWorkoutDone),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: log.isWorkoutDone
                      ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                      : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: log.isWorkoutDone
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.isWorkoutDone ? Icons.check : Icons.fitness_center,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.workoutName ?? "No Routine Selected",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        log.isWorkoutDone ? "Completed" : "Tap to complete",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!log.isWorkoutDone)
                    const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // LIST ITEMS
          _buildListRow(
            "Water Intake",
            "${(log.waterGlasses * (log.waterGlassSizeMl / 1000)).toStringAsFixed(2)} L",
            log.waterGlasses / 8,
            Colors.blue,
            Icons.water_drop,
            cardColor,
            textColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Steps Walked",
            "${log.steps} / 10k",
            log.steps / 10000,
            Colors.orange,
            Icons.directions_walk,
            cardColor,
            textColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Calories",
            "${log.totalCalories} / 2,400",
            log.totalCalories / 2400,
            Colors.red,
            Icons.local_fire_department,
            cardColor,
            textColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Sleep",
            "${log.sleepHours}h",
            0.8,
            Colors.deepPurple,
            Icons.bedtime,
            cardColor,
            textColor,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- MISSING HELPER ---
  Widget _buildListRow(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
    Color bg,
    Color text,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: text),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
