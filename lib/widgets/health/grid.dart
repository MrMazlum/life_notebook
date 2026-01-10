import 'package:flutter/material.dart';
import '../../models/health_model.dart';
import 'cards/nutrition.dart';
import 'cards/hydration.dart';
import 'activity/activity_card.dart';
import 'cards/weight_dialog.dart';

class HealthGrid extends StatelessWidget {
  final HealthDailyLog log;
  final double lastKnownWeight;
  final DateTime? lastWeightDate;
  final List<String> availableRoutines;

  final Function(int) onWaterChanged;
  final Function(int) onCaffeineChanged;
  final Function(int) onCaffeineConfigChanged;
  final Function(bool) onDietToggle;
  // CHANGED: Now accepts Steps AND Calories
  final Function(int, int) onStepsAndCaloriesChanged;
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
    required this.lastKnownWeight,
    required this.lastWeightDate,
    required this.availableRoutines,
    required this.onWaterChanged,
    required this.onCaffeineChanged,
    required this.onCaffeineConfigChanged,
    required this.onDietToggle,
    required this.onStepsAndCaloriesChanged, // Updated Name
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
                    availableRoutines: availableRoutines,
                    onRoutineChanged: onRoutineChanged,
                    onWorkoutToggle: onWorkoutToggle,
                    // Pass a simplified callback for simple step updates if needed,
                    // or just ignore if the card doesn't edit steps directly.
                    onStepsChanged: (s) =>
                        onStepsAndCaloriesChanged(s, log.burnedCalories),
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
              Expanded(child: _buildStepsCard(context, cardColor)),
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
                    multiplier: log.caffeineGlassSizeMg,
                    unit: "mg",
                    onAdd: () => onCaffeineChanged(log.caffeineAmount + 1),
                    onRemove: () => onCaffeineChanged(
                      log.caffeineAmount > 0 ? log.caffeineAmount - 1 : 0,
                    ),
                    onEditMultiplier: onCaffeineConfigChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context, Color cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Use stored value, or fallback to auto-calc if 0
    int displayBurned = log.burnedCalories > 0
        ? log.burnedCalories
        : (log.steps * 0.04).toInt();

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
                Icons.directions_walk_rounded,
                color: Colors.orange,
                size: 28,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${log.steps}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$displayBurned kcal",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
              _showStepDialog(context);
            },
          ),
        ),
      ],
    );
  }

  void _showStepDialog(BuildContext context) {
    TextEditingController stepCtrl = TextEditingController(
      text: log.steps > 0 ? log.steps.toString() : "",
    );
    // Pre-fill calories if they exist, otherwise calculate estimated
    int currentCal = log.burnedCalories > 0
        ? log.burnedCalories
        : (log.steps * 0.04).toInt();

    TextEditingController calCtrl = TextEditingController(
      text: currentCal > 0 ? currentCal.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Activity Data",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // STEPS INPUT
              TextField(
                controller: stepCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  labelText: "Steps",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                  suffixText: "steps",
                ),
                autofocus: true,
                onChanged: (val) {
                  // Auto-update calories when steps change (optional convenience)
                  int s = int.tryParse(val) ?? 0;
                  calCtrl.text = (s * 0.04).toInt().toString();
                },
              ),
              const SizedBox(height: 20),

              // CALORIES INPUT
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  labelText: "Burned Energy",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  suffixText: "kcal",
                  prefixIcon: Icon(
                    Icons.local_fire_department,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final int steps = int.tryParse(stepCtrl.text) ?? 0;
                final int cals = int.tryParse(calCtrl.text) ?? 0;

                onStepsAndCaloriesChanged(steps, cals);
                Navigator.pop(context);
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
        );
      },
    );
  }

  Widget _buildWeightCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    double displayWeight = log.weight > 0 ? log.weight : lastKnownWeight;

    String dateLabel = "";
    if (log.weight > 0) {
      dateLabel = "Measured today";
    } else if (lastWeightDate != null) {
      final diff = DateTime.now().difference(lastWeightDate!).inDays;
      if (diff == 0)
        dateLabel = "Measured today";
      else if (diff == 1)
        dateLabel = "Measured yesterday";
      else
        dateLabel = "Measured $diff days ago";
    } else {
      dateLabel = "No data yet";
    }

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
                    displayWeight.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "kg",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Expanded(
                        child: Text(
                          dateLabel,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  initialWeight: displayWeight,
                  onWeightChanged: onWeightChanged,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
