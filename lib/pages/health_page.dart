import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_model.dart';
import '../widgets/health/grid.dart';
import '../widgets/health/summary_card.dart';
import '../widgets/health/plan_view.dart'; // NEW IMPORT

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // ... [Keep ALL your existing state variables (streams, controllers, etc.)]
  DateTime _selectedDate = DateTime.now();
  late PageController _weekPageController;
  final int _initialPage = 1000;
  bool _forceInspectMode = false;

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  HealthDailyLog _currentLog = HealthDailyLog();

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculatePageForDate(DateTime.now());
    _weekPageController = PageController(initialPage: initialIndex);
    _loadSavedSteps();
    _subscribeToDate(_selectedDate);
    _initPedometer();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  // ... [Keep ALL your existing logic methods (_subscribeToDate, _saveToFirestore, etc.)]
  // (Paste them here exactly as they were in previous steps to avoid breaking logic)
  void _subscribeToDate(DateTime date) {
    _firestoreSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('health_logs')
        .doc(dateKey)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final cloudLog = HealthDailyLog.fromMap(snapshot.data()!, date);
            if (DateUtils.isSameDay(date, DateTime.now())) {
              setState(
                () => _currentLog = cloudLog.copyWith(steps: _currentLog.steps),
              );
            } else {
              setState(() => _currentLog = cloudLog);
            }
          } else {
            if (!DateUtils.isSameDay(date, DateTime.now())) {
              setState(() => _currentLog = HealthDailyLog(date: date));
            }
          }
        });
  }

  Future<void> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = "daily_steps_v2_${DateTime.now().day}";
    if (prefs.containsKey(todayKey)) {
      int savedSteps = prefs.getInt(todayKey) ?? 0;
      if (mounted)
        setState(() => _currentLog = _currentLog.copyWith(steps: savedSteps));
    }
  }

  void _initPedometer() async {
    if (await Permission.activityRecognition.request().isGranted) {
      Pedometer.stepCountStream.listen(_onStepCount).onError(_onStepError);
    }
  }

  void _onStepCount(StepCount event) async {
    int totalSensorSteps = event.steps;
    int todaySteps = await _calculateTodaySteps(totalSensorSteps);
    _saveStepsLocally(todaySteps);
    if (mounted) {
      setState(() => _currentLog = _currentLog.copyWith(steps: todaySteps));
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
    if (!prefs.containsKey(offsetKey))
      await prefs.setInt(offsetKey, sensorSteps);
    int offset = prefs.getInt(offsetKey) ?? sensorSteps;
    int calculated = sensorSteps - offset;
    return calculated < 0 ? sensorSteps : calculated;
  }

  void _onStepError(error) => debugPrint('Pedometer Error: $error');

  void _saveToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('health_logs')
        .doc(dateKey)
        .set(_currentLog.toMap(), SetOptions(merge: true));
  }

  void _updateLog(VoidCallback updateFn) {
    setState(() => updateFn());
    _saveToFirestore();
  }

  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = date.subtract(Duration(days: date.weekday - 1));
    return _initialPage + (mondayDate.difference(mondayNow).inDays / 7).round();
  }

  DateTime _getMondayForPage(int index) {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    return currentMonday.add(Duration(days: (index - _initialPage) * 7));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _forceInspectMode = false;
    });
    _subscribeToDate(date);
  }

  Future<void> _selectDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(
              headerBackgroundColor: Colors.deepOrange,
              headerForegroundColor: Colors.white,
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      _onDateSelected(picked);
      _weekPageController.animateToPage(
        _calculatePageForDate(picked),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleBackToToday(Color themeColor) {
    final now = DateTime.now();
    _onDateSelected(now);
    _weekPageController.animateToPage(
      _calculatePageForDate(now),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = Colors.deepOrange;
    final textColor = isDark ? Colors.white : Colors.black87;

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isFuture = _selectedDate.isAfter(DateTime.now()) && !isToday;

    Widget content;

    if (isFuture) {
      // Future: Show Full Page Planner
      content = WorkoutPlanView(
        log: _currentLog,
        onRoutineChanged: (name) =>
            _updateLog(() => _currentLog.workoutName = name),
        onLogUpdated: () => _updateLog(() {}), // Trigger save
      );
    } else if (isToday || _forceInspectMode) {
      // Today/Inspect: Show Grid
      content = _buildGrid();
    } else {
      // Past: Show Summary
      content = HealthSummaryView(
        log: _currentLog,
        onInspectDetails: () => setState(() => _forceInspectMode = true),
        onBackToToday: () => _handleBackToToday(themeColor),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHealthHeader(isDark, themeColor, textColor),
          Expanded(child: content),
        ],
      ),
    );
  }

  // _buildGrid helper remains the same...
  Widget _buildGrid() {
    return HealthGrid(
      log: _currentLog,
      onWaterChanged: (val) => _updateLog(() => _currentLog.waterGlasses = val),
      onUpdateGlassSize: (val) =>
          _updateLog(() => _currentLog.waterGlassSizeMl = val),
      onCaffeineChanged: (val) =>
          _updateLog(() => _currentLog.caffeineAmount = val),
      onMoodChanged: (val) => _updateLog(() => _currentLog.mood = val),
      onAddFood: (item) => _updateLog(() {
        _currentLog.foodLog.add(item);
        _currentLog.totalCalories += item.calories;
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
      onExerciseUpdated: () => _updateLog(() {}),
    );
  }

  // Header helper remains the same...
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
                GestureDetector(
                  onTap: () => _selectDateFromPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: themeColor,
                      size: 24,
                    ),
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
