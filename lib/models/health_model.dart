import 'package:flutter/material.dart';

class FoodItem {
  String name;
  int calories;
  int protein;
  int carbs;
  int fat;
  DateTime timestamp;

  FoodItem({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.timestamp,
  });
}

class HealthDailyLog {
  // Essentials
  int waterGlasses;
  int waterGlassSizeMl;
  int steps;
  double weight;
  int sleepHours;
  int mood;

  // Vitals
  int caffeineAmount;

  // NUTRITION
  List<FoodItem> foodLog;
  bool useMacros; // <--- THIS WAS THE MISSING KEY causing all the errors

  // Getters for Nutrition Summary
  int get totalCalories => foodLog.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein => foodLog.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => foodLog.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => foodLog.fold(0, (sum, item) => sum + item.fat);

  // Gym
  String? workoutName;
  bool isWorkoutDone;

  HealthDailyLog({
    this.waterGlasses = 0,
    this.waterGlassSizeMl = 250,
    this.steps = 0,
    this.weight = 70.0,
    this.sleepHours = 7,
    this.mood = 3,
    this.caffeineAmount = 0,
    this.useMacros = false, // Default is OFF (Simple mode)
    List<FoodItem>? foodLog,
    this.workoutName,
    this.isWorkoutDone = false,
  }) : foodLog = foodLog ?? [];
}
