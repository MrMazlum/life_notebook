import 'package:flutter/material.dart';
// Note: We don't even need cloud_firestore here anymore because the model handles it!
import '../../models/dashboard_models.dart';

class HealthCard extends StatelessWidget {
  final VoidCallback onNavigate;
  const HealthCard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = Colors.deepOrange;

    // FIX: StreamBuilder now listens to Map<String, dynamic>
    return StreamBuilder<Map<String, dynamic>>(
      stream: DashboardModel().getDailyHealth(),
      builder: (context, snapshot) {
        int steps = 0;
        int kcal = 0;
        double water = 0;

        if (snapshot.hasData) {
          final data = snapshot.data!;
          steps = data['steps'] ?? 0;
          kcal = data['calories'] ?? 0;
          // The model now returns water in Liters as a double
          water = (data['waterLiters'] ?? 0.0).toDouble();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border(bottom: BorderSide(color: accent, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        "BODY STATUS",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  _buildArrowButton(accent, onNavigate),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_run, color: accent, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "$steps",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Steps Taken Today",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMiniStat("$kcal", "Kcal"),
                      const SizedBox(width: 20),
                      _buildMiniStat("${water.toStringAsFixed(1)}L", "Water"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArrowButton(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildMiniStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
