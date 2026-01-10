// lib/widgets/health/activity/exercise_models.dart

class SetDetail {
  int reps;
  double weight;

  SetDetail({this.reps = 10, this.weight = 0.0});

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight};

  // Create from Map (handle type safety)
  factory SetDetail.fromMap(Map<String, dynamic> map) {
    return SetDetail(
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }
}

class ExerciseDetail {
  String name;
  List<SetDetail> sets;

  ExerciseDetail({required this.name, List<SetDetail>? sets})
    : sets = sets ?? [SetDetail(), SetDetail(), SetDetail()];

  Map<String, dynamic> toMap() => {
    'name': name,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory ExerciseDetail.fromMap(Map<String, dynamic> map) {
    return ExerciseDetail(
      name: map['name'] ?? '',
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((s) => SetDetail.fromMap(s))
              .toList() ??
          [],
    );
  }
}

// Global Master List of Exercises (for search)
// In a real app, this could also come from Firestore.
final List<String> masterExerciseList = [
  "Bench Press",
  "Incline Dumbbell Press",
  "Push Ups",
  "Overhead Press",
  "Lateral Raises",
  "Tricep Extensions",
  "Skullcrushers",
  "Dips",
  "Pull Ups",
  "Lat Pulldown",
  "Barbell Row",
  "Dumbbell Row",
  "Face Pulls",
  "Bicep Curls",
  "Hammer Curls",
  "Preacher Curls",
  "Deadlift",
  "Squat",
  "Leg Press",
  "Leg Extension",
  "Hamstring Curl",
  "Lunges",
  "Bulgarian Split Squat",
  "Calf Raises",
  "Hip Thrust",
  "Treadmill Run",
  "Cycling",
  "Elliptical",
  "Jump Rope",
  "Burpees",
  "Plank",
  "Crunch",
  "Leg Raise",
  "Russian Twist",
];
