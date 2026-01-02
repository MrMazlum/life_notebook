import 'package:flutter/material.dart';

class GymPage extends StatelessWidget {
  const GymPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '🏋️ Gym Workouts will be here',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}