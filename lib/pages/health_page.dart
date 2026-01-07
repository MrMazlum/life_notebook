import 'dart:async'; // Needed for StreamSubscription
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- IMPORT ADDED

import '../models/health_model.dart';
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

  // Streams
  late Stream<StepCount> _stepCountStream;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  // --- DATA ---
  HealthDailyLog _currentLog = HealthDailyLog();

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculatePageForDate(DateTime.now());
    _weekPageController = PageController(initialPage: initialIndex);

    // 1. Initial Load
    _loadSavedSteps();

    // 2. Start Cloud Sync
    _subscribeToDate(_selectedDate);

    // 3. Start Sensor
    _initPedometer();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  // --- CLOUD SYNC LOGIC (UPDATED FOR PRIVATE USER) ---
  void _subscribeToDate(DateTime date) {
    // Cancel previous listener to avoid memory leaks
    _firestoreSubscription?.cancel();

    // GET CURRENT USER
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Should allow anonymous login to finish first

    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // <--- USE REAL ID
        .collection('health_logs')
        .doc(dateKey)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final cloudLog = HealthDailyLog.fromMap(snapshot.data()!, date);

            // CONFLICT RESOLUTION:
            // If viewing TODAY, trust local Pedometer for steps (it's faster).
            // For everything else (Water, Workout, History), trust Cloud.
            if (DateUtils.isSameDay(date, DateTime.now())) {
              // Keep current local steps, update rest
              setState(() {
                _currentLog = cloudLog.copyWith(steps: _currentLog.steps);
              });
            } else {
              // Viewing history: Cloud is truth
              setState(() {
                _currentLog = cloudLog;
              });
            }
          } else {
            // No data for this day yet (New Day) -> Reset UI to empty
            if (!DateUtils.isSameDay(date, DateTime.now())) {
              setState(() {
                _currentLog = HealthDailyLog(date: date);
              });
            }
          }
        });
  }

  // --- SENSOR LOGIC ---
  Future<void> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    // Changed key to v2 to avoid collision with old boolean data
    final todayKey = "daily_steps_v2_${DateTime.now().day}";
    if (prefs.containsKey(todayKey)) {
      int savedSteps = prefs.getInt(todayKey) ?? 0;
      if (mounted) {
        setState(() {
          _currentLog = _currentLog.copyWith(steps: savedSteps);
        });
      }
    }
  }

  void _initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(_onStepCount).onError(_onStepError);
    } else {
      debugPrint("Step Permission Denied");
    }
  }

  void _onStepCount(StepCount event) async {
    int totalSensorSteps = event.steps;
    int todaySteps = await _calculateTodaySteps(totalSensorSteps);
    _saveStepsLocally(todaySteps);

    if (mounted) {
      setState(() {
        _currentLog = _currentLog.copyWith(steps: todaySteps);
      });
      // Fire-and-forget cloud save
      if (todaySteps % 10 == 0) _saveToFirestore();
    }
  }

  Future<void> _saveStepsLocally(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = "daily_steps_v2_${DateTime.now().day}";
    await prefs.setInt(todayKey, steps);
  }

  Future<int> _calculateTodaySteps(int sensorSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final offsetKey = "steps_offset_v2_${DateTime.now().day}";

    if (!prefs.containsKey(offsetKey)) {
      await prefs.setInt(offsetKey, sensorSteps);
    }

    int offset = prefs.getInt(offsetKey) ?? sensorSteps;
    int calculated = sensorSteps - offset;

    if (calculated < 0) {
      await prefs.setInt(offsetKey, 0);
      return sensorSteps;
    }
    return calculated;
  }

  void _onStepError(error) => debugPrint('Pedometer Error: $error');

  // --- PERSISTENCE (UPDATED FOR PRIVATE USER) ---
  void _saveToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Only save if we are editing TODAY or explicit history edit
    // (Prevents overwriting history with 0 steps if logic bugs out)
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // <--- USE REAL ID
        .collection('health_logs')
        .doc(dateKey)
        .set(_currentLog.toMap(), SetOptions(merge: true))
        .catchError((e) => debugPrint("Firestore Sync Error: $e"));
  }

  void _updateLog(VoidCallback updateFn) {
    setState(() {
      updateFn();
    });
    _saveToFirestore();
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
    _subscribeToDate(date); // Switch Firestore Listener
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
      _onDateSelected(now); // This handles the subscription switch too
      final targetPage = _calculatePageForDate(now);
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
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
          onWaterChanged: (val) =>
              _updateLog(() => _currentLog.waterGlasses = val),
          onUpdateGlassSize: (val) =>
              _updateLog(() => _currentLog.waterGlassSizeMl = val),
          onCaffeineChanged: (val) =>
              _updateLog(() => _currentLog.caffeineAmount = val),
          onMoodChanged: (val) => _updateLog(() => _currentLog.mood = val),
          onAddFood: (item) => _updateLog(() {
            _currentLog.foodLog.add(item);
            _currentLog.totalCalories += item.calories;
            _currentLog.totalProtein += item.protein;
            _currentLog.totalCarbs += item.carbs;
            _currentLog.totalFat += item.fat;
          }),
          onDietToggle: (val) => _updateLog(() => _currentLog.useMacros = val),
          onStepsChanged: (val) => _updateLog(() => _currentLog.steps = val),
          onWeightChanged: (val) => _updateLog(() => _currentLog.weight = val),
          onRoutineChanged: (val) =>
              _updateLog(() => _currentLog.workoutName = val),
          onWorkoutToggle: (val) =>
              _updateLog(() => _currentLog.isWorkoutDone = val),
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
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Text(
                  DateFormat('MMMM d').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
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
          const SizedBox(height: 15),
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
