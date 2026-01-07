import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// MODELS
import '../models/health_model.dart';

// WIDGET IMPORTS
import '../widgets/health/grid.dart';
import '../widgets/health/list.dart';
import '../widgets/health/hero.dart';

enum HealthViewType { grid, list, hero }

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // --- STATE ---
  DateTime _selectedDate = DateTime.now();
  HealthViewType _currentView = HealthViewType.grid;
  late PageController _weekPageController;
  final int _initialPage = 1000;

  // --- DATA ---
  HealthDailyLog _currentLog = HealthDailyLog(
    waterGlasses: 5,
    waterGlassSizeMl: 250,
    steps: 6240,
    weight: 72.5,
    workoutName: "Push Day A",
    isWorkoutDone: false,
    mood: 3,
    caffeineAmount: 1,
    foodLog: [],
  );

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculatePageForDate(DateTime.now());
    _weekPageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  // --- DATE LOGIC ---
  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = date.subtract(Duration(days: date.weekday - 1));
    final diff = mondayDate.difference(mondayNow).inDays;
    return _initialPage + (diff / 7).round();
  }

  DateTime _getMondayForPage(int index) {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final weeksDiff = index - _initialPage;
    return currentMonday.add(Duration(days: weeksDiff * 7));
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _handleBackToToday(Color themeColor) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(_selectedDate, now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You are already up to date!"),
          backgroundColor: themeColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _selectedDate = now);
      final targetPage = _calculatePageForDate(now);
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _updateLog(VoidCallback updateFn) {
    setState(() {
      updateFn();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = Colors.deepOrange;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHealthHeader(isDark, themeColor, textColor),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_currentView),
                child: _buildCurrentView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case HealthViewType.grid:
        return HealthGrid(
          log: _currentLog,
          // Hydration
          onWaterChanged: (val) =>
              _updateLog(() => _currentLog.waterGlasses = val),
          onUpdateGlassSize: (val) =>
              _updateLog(() => _currentLog.waterGlassSizeMl = val),
          onCaffeineChanged: (val) =>
              _updateLog(() => _currentLog.caffeineAmount = val),
          // Mood
          onMoodChanged: (val) => _updateLog(() => _currentLog.mood = val),
          // Nutrition
          onAddFood: (item) => _updateLog(() => _currentLog.foodLog.add(item)),
          onDietToggle: (val) => _updateLog(() => _currentLog.useMacros = val),
          // Activity
          onStepsChanged: (val) => _updateLog(() => _currentLog.steps = val),
          onWeightChanged: (val) => _updateLog(() => _currentLog.weight = val),
          onRoutineChanged: (val) =>
              _updateLog(() => _currentLog.workoutName = val),
          onWorkoutToggle: (val) =>
              _updateLog(() => _currentLog.isWorkoutDone = val),
          // Legacy/Unused
          onCaloriesChanged: (val) {},
          onMacrosChanged: (p, c, f) {},
        );

      case HealthViewType.list:
        return HealthList(
          log: _currentLog,
          onWorkoutToggle: (val) =>
              _updateLog(() => _currentLog.isWorkoutDone = val),
        );

      case HealthViewType.hero:
        return HealthHero(log: _currentLog);
    }
  }

  Widget _buildHealthHeader(bool isDark, Color themeColor, Color textColor) {
    return Container(
      // FIXED: Matched Top Padding (15) to Bottom Spacing (15)
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => _handleBackToToday(themeColor),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.undo_rounded,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                ),
                // Date
                Text(
                  DateFormat('MMMM d').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                // Toggle View
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildToggleBtn(
                        Icons.grid_view_rounded,
                        HealthViewType.grid,
                        themeColor,
                        isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildToggleBtn(
                        Icons.view_list_rounded,
                        HealthViewType.list,
                        themeColor,
                        isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildToggleBtn(
                        Icons.donut_large_rounded,
                        HealthViewType.hero,
                        themeColor,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Spacing (The Blue Arrow Reference)
          const SizedBox(height: 15),

          // WEEK STRIP
          SizedBox(
            height: 70,
            child: PageView.builder(
              controller: _weekPageController,
              itemBuilder: (context, index) {
                final monday = _getMondayForPage(index);
                final weekDays = List.generate(
                  7,
                  (i) => monday.add(Duration(days: i)),
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays
                      .map((date) => _buildDayItem(date, themeColor, isDark))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    IconData icon,
    HealthViewType type,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _currentView == type;
    return GestureDetector(
      onTap: () => setState(() => _currentView = type),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white54 : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDayItem(DateTime date, Color themeColor, bool isDark) {
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Expanded(
      child: GestureDetector(
        onTap: () => _onDateSelected(date),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? themeColor
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: isToday && !isSelected
                ? Border.all(color: themeColor.withOpacity(0.5), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E').format(date).substring(0, 3),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.grey),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
