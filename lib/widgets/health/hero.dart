import 'package:flutter/material.dart';
import '../../models/health_model.dart';

class HealthHero extends StatelessWidget {
  final HealthDailyLog log;

  const HealthHero({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // HERO SECTION
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  "Activity Score",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Steps Ring
                      SizedBox(
                        height: 180,
                        width: 180,
                        child: CircularProgressIndicator(
                          value: (log.steps / 10000).clamp(0.0, 1.0),
                          strokeWidth: 14,
                          color: Colors.green,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Calories Ring
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: CircularProgressIndicator(
                          value: (log.totalCalories / 2400).clamp(0.0, 1.0),
                          strokeWidth: 14,
                          color: Colors.blue,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Water Ring
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(
                          value: (log.waterGlasses / 8).clamp(0.0, 1.0),
                          strokeWidth: 14,
                          color: Colors.orange,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHeroLegend(
                      "Steps",
                      "${log.steps}",
                      Colors.green,
                      textColor,
                    ),
                    _buildHeroLegend(
                      "Cals",
                      "${log.totalCalories}",
                      Colors.blue,
                      textColor,
                    ),
                    _buildHeroLegend(
                      "Water",
                      "${(log.waterGlasses * 0.25)}L",
                      Colors.orange,
                      textColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WEIGHT TILE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight_rounded, color: textColor),
                    const SizedBox(width: 12),
                    Text(
                      "Weight Tracker",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${log.weight} kg",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- MISSING HELPER ---
  Widget _buildHeroLegend(String label, String val, Color color, Color text) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: text,
          ),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
