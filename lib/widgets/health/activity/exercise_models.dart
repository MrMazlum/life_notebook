// lib/widgets/health/activity/exercise_models.dart

class SetDetail {
  int reps;
  double weight;

  SetDetail({this.reps = 10, this.weight = 0.0});
}

class ExerciseDetail {
  String name;
  List<SetDetail> sets;

  ExerciseDetail({required this.name, List<SetDetail>? sets})
    : sets = sets ?? [SetDetail(), SetDetail(), SetDetail()]; // Default 3 sets
}

// Master List of Exercises (In-Memory Database)
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
