import 'package:cloud_firestore/cloud_firestore.dart';
// IMPORT THE EXERCISE MODELS
import '../widgets/health/activity/exercise_models.dart';

class FoodItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;

  FoodItem({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class HealthDailyLog {
  DateTime date;

  // Activity
  int steps;
  String? workoutName;
  bool isWorkoutDone;
  // NEW: Store the actual exercises performed
  List<ExerciseDetail> workoutLog;
  double weight;

  // Hydration
  int waterGlasses;
  int waterGlassSizeMl;
  int caffeineAmount;

  // Nutrition
  bool useMacros;
  List<FoodItem> foodLog;
  int totalCalories;
  int totalProtein;
  int totalCarbs;
  int totalFat;

  // Mood & Sleep
  int mood;
  double sleepHours;

  HealthDailyLog({
    DateTime? date,
    this.steps = 0,
    this.workoutName,
    this.isWorkoutDone = false,
    List<ExerciseDetail>? workoutLog, // NEW
    this.weight = 0.0,
    this.waterGlasses = 0,
    this.waterGlassSizeMl = 250,
    this.caffeineAmount = 0,
    this.useMacros = false,
    List<FoodItem>? foodLog,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.mood = 3,
    this.sleepHours = 7.0,
  }) : date = date ?? DateTime.now(),
       foodLog = foodLog ?? [],
       workoutLog = workoutLog ?? []; // NEW

  HealthDailyLog copyWith({
    DateTime? date,
    int? steps,
    String? workoutName,
    bool? isWorkoutDone,
    List<ExerciseDetail>? workoutLog, // NEW
    double? weight,
    int? waterGlasses,
    int? waterGlassSizeMl,
    int? caffeineAmount,
    bool? useMacros,
    List<FoodItem>? foodLog,
    int? totalCalories,
    int? totalProtein,
    int? totalCarbs,
    int? totalFat,
    int? mood,
    double? sleepHours,
  }) {
    return HealthDailyLog(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      workoutName: workoutName ?? this.workoutName,
      isWorkoutDone: isWorkoutDone ?? this.isWorkoutDone,
      workoutLog: workoutLog ?? this.workoutLog, // NEW
      weight: weight ?? this.weight,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      waterGlassSizeMl: waterGlassSizeMl ?? this.waterGlassSizeMl,
      caffeineAmount: caffeineAmount ?? this.caffeineAmount,
      useMacros: useMacros ?? this.useMacros,
      foodLog: foodLog ?? this.foodLog,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      mood: mood ?? this.mood,
      sleepHours: sleepHours ?? this.sleepHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'steps': steps,
      'workoutName': workoutName,
      'isWorkoutDone': isWorkoutDone,
      'workoutLog': workoutLog.map((e) => e.toMap()).toList(), // NEW
      'weight': weight,
      'waterGlasses': waterGlasses,
      'waterGlassSizeMl': waterGlassSizeMl,
      'caffeineAmount': caffeineAmount,
      'useMacros': useMacros,
      'foodLog': foodLog.map((f) => f.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'mood': mood,
      'sleepHours': sleepHours,
    };
  }

  factory HealthDailyLog.fromMap(Map<String, dynamic> map, DateTime docDate) {
    var loadedFood = <FoodItem>[];
    if (map['foodLog'] != null) {
      loadedFood = (map['foodLog'] as List)
          .map((e) => FoodItem.fromMap(e))
          .toList();
    }

    // NEW: Load Exercises
    var loadedExercises = <ExerciseDetail>[];
    if (map['workoutLog'] != null) {
      loadedExercises = (map['workoutLog'] as List)
          .map((e) => ExerciseDetail.fromMap(e))
          .toList();
    }

    return HealthDailyLog(
      date: docDate,
      steps: map['steps'] ?? 0,
      workoutName: map['workoutName'],
      isWorkoutDone: map['isWorkoutDone'] ?? false,
      workoutLog: loadedExercises, // NEW
      weight: (map['weight'] ?? 0.0).toDouble(),
      waterGlasses: map['waterGlasses'] ?? 0,
      waterGlassSizeMl: map['waterGlassSizeMl'] ?? 250,
      caffeineAmount: map['caffeineAmount'] ?? 0,
      useMacros: map['useMacros'] ?? false,
      foodLog: loadedFood,
      totalCalories: map['totalCalories'] ?? 0,
      totalProtein: map['totalProtein'] ?? 0,
      totalCarbs: map['totalCarbs'] ?? 0,
      totalFat: map['totalFat'] ?? 0,
      mood: map['mood'] ?? 3,
      sleepHours: (map['sleepHours'] ?? 7.0).toDouble(),
    );
  }
}
