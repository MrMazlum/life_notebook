import 'package:flutter/material.dart';

class QuickActionSheet extends StatelessWidget {
  final VoidCallback onLogWeight;
  final VoidCallback onAddFood;
  final VoidCallback onStartWorkout;
  final VoidCallback onLogWater;
  final VoidCallback onLogSteps;

  const QuickActionSheet({
    super.key,
    required this.onLogWeight,
    required this.onAddFood,
    required this.onStartWorkout,
    required this.onLogWater,
    required this.onLogSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionBtn(
                context,
                "Workout",
                Icons.fitness_center_rounded,
                Colors.orange,
                onStartWorkout,
              ),
              _buildActionBtn(
                context,
                "Food",
                Icons.restaurant_menu_rounded,
                Colors.green,
                onAddFood,
              ),
              _buildActionBtn(
                context,
                "Water",
                Icons.water_drop_rounded,
                Colors.blue,
                onLogWater,
              ),
              _buildActionBtn(
                context,
                "Weight",
                Icons.monitor_weight_rounded,
                Colors.purple,
                onLogWeight,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Full width button for steps
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onLogSteps();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions_walk, color: Colors.deepOrange),
              label: Text(
                "Log Steps Manually",
                style: TextStyle(color: textColor),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close the sheet first
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
