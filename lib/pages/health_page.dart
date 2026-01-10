import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_model.dart';
import '../widgets/health/activity/exercise_models.dart';
import '../widgets/health/grid.dart';
import '../widgets/health/summary_card.dart';
import '../widgets/health/plan_view.dart';
import '../widgets/health/quick_actions.dart';
import '../widgets/health/cards/weight_dialog.dart';
import '../widgets/health/cards/nutrition.dart';
import '../widgets/health/activity/routine_manager.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  late PageController _weekPageController;
  final int _initialPage = 1000;
  bool _forceInspectMode = false;

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  HealthDailyLog _currentLog = HealthDailyLog();

  double _lastKnownWeight = 0.0;
  DateTime? _lastWeightDate;
  List<String> _customRoutines = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initialIndex = _calculatePageForDate(DateTime.now());
    _weekPageController = PageController(initialPage: initialIndex);

    _loadGlobalUserData();
    _subscribeToDate(_selectedDate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weekPageController.dispose();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionSheet(
        onLogWeight: _showWeightDialog,
        onAddFood: _showAddFoodSheet,
        onStartWorkout: _showRoutineManager,
        onLogWater: _quickLogWater,
        onLogSteps: _showStepEntryDialog,
      ),
    );
  }

  void _showWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => WeightPickerDialog(
        initialWeight: _currentLog.weight > 0
            ? _currentLog.weight
            : _lastKnownWeight,
        onWeightChanged: (val) {
          _updateLog(() => _currentLog.weight = val);
          _saveGlobalStats();
        },
      ),
    );
  }

  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddFoodSheet(
        onAdd: (item) {
          _updateLog(() {
            _currentLog.foodLog.add(item);
            _currentLog.totalCalories += item.calories;
            _currentLog.totalProtein += item.protein;
            _currentLog.totalCarbs += item.carbs;
            _currentLog.totalFat += item.fat;
          });
        },
      ),
    );
  }

  void _showRoutineManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => RoutineManagerSheet(
          selectedRoutine: _currentLog.workoutName,
          availableRoutines: _customRoutines,
          onSelected: (routineName) {
            _onRoutineCreatedOrUpdated(routineName);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _quickLogWater() {
    _updateLog(() => _currentLog.waterGlasses += 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Water logged! Total: ${_currentLog.waterGlasses * _currentLog.waterGlassSizeMl}ml",
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showStepEntryDialog() {
    TextEditingController stepCtrl = TextEditingController(
      text: _currentLog.steps > 0 ? _currentLog.steps.toString() : "",
    );
    int currentCal = _currentLog.burnedCalories > 0
        ? _currentLog.burnedCalories
        : (_currentLog.steps * 0.04).toInt();
    TextEditingController calCtrl = TextEditingController(
      text: currentCal > 0 ? currentCal.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Enter Activity",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  int s = int.tryParse(val) ?? 0;
                  calCtrl.text = (s * 0.04).toInt().toString();
                },
              ),
              const SizedBox(height: 20),
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

                _updateLog(() {
                  _currentLog.steps = steps;
                  _currentLog.burnedCalories = cals;
                });
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

  // --- BOILERPLATE BELOW (Unchanged) ---
  Future<void> _loadGlobalUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists && userDoc.data() != null) {
      if (mounted) {
        setState(() {
          _lastKnownWeight = (userDoc.data()!['latestWeight'] ?? 0.0)
              .toDouble();
          if (userDoc.data()!['latestWeightDate'] != null) {
            _lastWeightDate = (userDoc.data()!['latestWeightDate'] as Timestamp)
                .toDate();
          }
          if (userDoc.data()!['customRoutines'] != null) {
            _customRoutines = List<String>.from(
              userDoc.data()!['customRoutines'],
            );
          }
        });
      }
    }
  }

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
              setState(() {
                _currentLog = cloudLog;
                if (_currentLog.weight == 0.0 && _lastKnownWeight > 0) {
                  _currentLog.weight = _lastKnownWeight;
                }
              });
            } else {
              setState(() => _currentLog = cloudLog);
            }
          } else {
            setState(() {
              _currentLog = HealthDailyLog(date: date);
              if (_lastKnownWeight > 0) _currentLog.weight = _lastKnownWeight;
            });
          }
        });
  }

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

  void _saveGlobalStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'latestWeight': _currentLog.weight > 0
          ? _currentLog.weight
          : _lastKnownWeight,
      'latestWeightDate': _currentLog.weight > 0
          ? Timestamp.fromDate(_selectedDate)
          : null,
      'customRoutines': _customRoutines,
    }, SetOptions(merge: true));
  }

  void _updateLog(VoidCallback updateFn) {
    setState(() => updateFn());
    _saveToFirestore();
  }

  void _onRoutineCreatedOrUpdated(String? routineName) {
    if (routineName == null) {
      _updateLog(() => _currentLog.workoutName = null);
      return;
    }
    if (!_customRoutines.contains(routineName)) {
      setState(() => _customRoutines.add(routineName));
      _saveGlobalStats();
    }
    _updateLog(() => _currentLog.workoutName = routineName);
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
      content = WorkoutPlanView(
        log: _currentLog,
        availableRoutines: _customRoutines,
        onRoutineChanged: _onRoutineCreatedOrUpdated,
        onLogUpdated: () => _updateLog(() {}),
      );
    } else if (isToday || _forceInspectMode) {
      content = _buildGrid();
    } else {
      content = HealthSummaryView(
        log: _currentLog,
        onInspectDetails: () => setState(() => _forceInspectMode = true),
        onBackToToday: () => _handleBackToToday(themeColor),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isToday
          ? FloatingActionButton(
              onPressed: _showQuickActionMenu,
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: Column(
        children: [
          _buildHealthHeader(isDark, themeColor, textColor),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return HealthGrid(
      log: _currentLog,
      lastKnownWeight: _lastKnownWeight,
      lastWeightDate: _lastWeightDate,
      availableRoutines: _customRoutines,
      onWaterChanged: (val) => _updateLog(() => _currentLog.waterGlasses = val),
      onUpdateGlassSize: (val) =>
          _updateLog(() => _currentLog.waterGlassSizeMl = val),
      onCaffeineChanged: (val) =>
          _updateLog(() => _currentLog.caffeineAmount = val),
      onCaffeineConfigChanged: (val) =>
          _updateLog(() => _currentLog.caffeineGlassSizeMg = val),
      onDietToggle: (val) => _updateLog(() => _currentLog.useMacros = val),
      onAddFood: (item) => _updateLog(() {
        _currentLog.foodLog.add(item);
        _currentLog.totalCalories += item.calories;
        _currentLog.totalProtein += item.protein;
        _currentLog.totalCarbs += item.carbs;
        _currentLog.totalFat += item.fat;
      }),
      onStepsAndCaloriesChanged: (steps, calories) {
        _updateLog(() {
          _currentLog.steps = steps;
          _currentLog.burnedCalories = calories;
        });
      },
      onWeightChanged: (val) {
        _updateLog(() => _currentLog.weight = val);
        _saveGlobalStats();
      },
      onRoutineChanged: _onRoutineCreatedOrUpdated,
      onWorkoutToggle: (val) =>
          _updateLog(() => _currentLog.isWorkoutDone = val),
      onCaloriesChanged: (val) {},
      onMacrosChanged: (p, c, f) {},
      onExerciseUpdated: () => _updateLog(() {}),
    );
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
