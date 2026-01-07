import 'package:flutter/material.dart';
import '../../models/health_model.dart';
import 'cards/nutrition.dart';
import 'cards/hydration.dart';
import 'activity/activity_card.dart';
import 'cards/weight_dialog.dart';

class HealthGrid extends StatelessWidget {
  final HealthDailyLog log;
  final Function(int) onWaterChanged;
  final Function(int) onCaffeineChanged;
  final Function(int) onMoodChanged;
  final Function(bool) onDietToggle;
  final Function(int) onStepsChanged;
  final Function(double) onWeightChanged;
  final Function(String?) onRoutineChanged;
  final Function(bool) onWorkoutToggle;
  final Function(FoodItem) onAddFood;
  final Function(int) onUpdateGlassSize;
  final Function(int) onCaloriesChanged;
  final Function(int, int, int) onMacrosChanged;
  final VoidCallback onExerciseUpdated;

  const HealthGrid({
    super.key,
    required this.log,
    required this.onWaterChanged,
    required this.onCaffeineChanged,
    required this.onMoodChanged,
    required this.onDietToggle,
    required this.onStepsChanged,
    required this.onWeightChanged,
    required this.onRoutineChanged,
    required this.onWorkoutToggle,
    required this.onAddFood,
    required this.onUpdateGlassSize,
    required this.onCaloriesChanged,
    required this.onMacrosChanged,
    required this.onExerciseUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // GYM & NUTRITION
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ActivityCard(
                    log: log,
                    onRoutineChanged: onRoutineChanged,
                    onWorkoutToggle: onWorkoutToggle,
                    onStepsChanged: onStepsChanged,
                    onWeightChanged: onWeightChanged,
                    onExerciseUpdated: onExerciseUpdated,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NutritionCard(
                    log: log,
                    onAddFood: onAddFood,
                    onDietToggle: onDietToggle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // STEPS & WEIGHT
          Row(
            children: [
              Expanded(
                child: _buildSimpleCard(
                  context,
                  Icons.directions_walk,
                  "Steps",
                  "${log.steps}",
                  "steps",
                  Colors.orange,
                  cardColor,
                  () => onStepsChanged(log.steps),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildWeightCard(context)),
            ],
          ),
          const SizedBox(height: 16),

          // HYDRATION
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: HydrationCard(
                    title: "Water",
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    value: log.waterGlasses,
                    multiplier: log.waterGlassSizeMl,
                    unit: "ml",
                    onAdd: () => onWaterChanged(log.waterGlasses + 1),
                    onRemove: () => onWaterChanged(
                      log.waterGlasses > 0 ? log.waterGlasses - 1 : 0,
                    ),
                    onEditMultiplier: onUpdateGlassSize,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: HydrationCard(
                    title: "Caffeine",
                    icon: Icons.coffee,
                    color: Colors.brown,
                    value: log.caffeineAmount,
                    multiplier: 95, // Avg mg per cup
                    unit: "mg",
                    // FIX: Changed +50 to +1 (1 cup)
                    onAdd: () => onCaffeineChanged(log.caffeineAmount + 1),
                    onRemove: () => onCaffeineChanged(
                      log.caffeineAmount > 0 ? log.caffeineAmount - 1 : 0,
                    ),
                    onEditMultiplier: (val) {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MOOD
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [1, 2, 3, 4, 5].map((level) {
                final isSelected = log.mood == level;
                final emojis = ["😫", "😐", "🙂", "😁", "🤩"];
                return GestureDetector(
                  onTap: () => onMoodChanged(level),
                  child: AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Text(
                        emojis[level - 1],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.monitor_weight_rounded,
                color: Colors.deepPurple,
                size: 28,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${log.weight}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Text(
                    "kg",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => WeightPickerDialog(
                  initialWeight: log.weight,
                  onWeightChanged: onWeightChanged,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String unit,
    Color color,
    Color bg,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
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
