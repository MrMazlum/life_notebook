import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GymPage extends StatefulWidget {
  const GymPage({super.key});

  @override
  State<GymPage> createState() => _GymPageState();
}

class _GymPageState extends State<GymPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Design Options"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          indicatorColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "1. Grid"),
            Tab(text: "2. List"),
            Tab(text: "3. Hero"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DesignOption1(), // The "Bento Box" Grid
          DesignOption2(), // The "Journal" List
          DesignOption3(), // The "Visual" Hero
        ],
      ),
    );
  }
}

// =========================================================
// OPTION 1: THE "BENTO BOX" GRID
// Focus: Organized, colorful, easy to tap buttons.
// =========================================================
class DesignOption1 extends StatelessWidget {
  const DesignOption1({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("Dashboard"),
          const SizedBox(height: 20),
          // MOOD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("😫", style: TextStyle(fontSize: 28)),
                Text("😐", style: TextStyle(fontSize: 28)),
                Text("🙂", style: TextStyle(fontSize: 28)),
                Text("🤩", style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2x2 GRID
          Row(
            children: [
              Expanded(
                child: _buildSquare(
                  Icons.water_drop,
                  "Water",
                  "1.2L",
                  Colors.blue,
                  cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSquare(
                  Icons.directions_walk,
                  "Steps",
                  "4,200",
                  Colors.orange,
                  cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSquare(
                  Icons.local_fire_department,
                  "Cals",
                  "1,200",
                  Colors.red,
                  cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSquare(
                  Icons.monitor_weight,
                  "Weight",
                  "72kg",
                  Colors.green,
                  cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // HABITS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Habits",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text("💊 Vitamins"),
                      backgroundColor: Colors.green.withOpacity(0.2),
                    ),
                    Chip(
                      label: const Text("📖 Reading"),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                    Chip(
                      label: const Text("🧘 Meditate"),
                      backgroundColor: Colors.purple.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquare(
    IconData icon,
    String title,
    String value,
    Color color,
    Color bg,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// OPTION 2: THE "JOURNAL" LIST
// Focus: Clean, horizontal bars, looks like a logbook.
// =========================================================
class DesignOption2 extends StatelessWidget {
  const DesignOption2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader("Daily Log"),
          const SizedBox(height: 20),

          // GYM CARD (Wide)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Push Day B",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "1h 20m • 8 Exercises",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // LIST ITEMS
          _buildListRow(
            "Water Intake",
            "1.2 / 2.5 L",
            0.5,
            Colors.blue,
            Icons.water_drop,
            cardColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Steps Walked",
            "4,200 / 10k",
            0.4,
            Colors.orange,
            Icons.directions_walk,
            cardColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Calories",
            "1,200 / 2,400",
            0.5,
            Colors.red,
            Icons.local_fire_department,
            cardColor,
          ),
          const SizedBox(height: 12),
          _buildListRow(
            "Sleep",
            "7h 12m",
            0.8,
            Colors.purple,
            Icons.bedtime,
            cardColor,
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
    Color bg,
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// OPTION 3: THE "VISUAL" HERO
// Focus: Big sleek rings, modern aesthetic, dashboard feel.
// =========================================================
class DesignOption3 extends StatelessWidget {
  const DesignOption3({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Text(
                  "Activity Score",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 12,
                        color: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      width: 110,
                      child: CircularProgressIndicator(
                        value: 0.5,
                        strokeWidth: 12,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: CircularProgressIndicator(
                        value: 0.3,
                        strokeWidth: 12,
                        color: Colors.red,
                        backgroundColor: Colors.red.withOpacity(0.1),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Icon(Icons.bolt, size: 30, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Text(
                      "🔥 400",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "💧 1.2L",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "👣 4k",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PILLS
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("Mood", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 5),
                        Text("🙂", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("Sleep", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 5),
                        Text(
                          "7.5h",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Weight Tracker",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: const [
                    Text(
                      "72.5 kg",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for the headers
Widget _buildHeader(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
    ],
  );
}
