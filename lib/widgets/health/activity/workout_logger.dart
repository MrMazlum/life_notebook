import 'package:flutter/material.dart';
import 'exercise_models.dart';

class WorkoutLoggerSheet extends StatefulWidget {
  final String exerciseName;
  final int targetSetCount;
  final Function(bool) onComplete;

  const WorkoutLoggerSheet({
    super.key,
    required this.exerciseName,
    required this.targetSetCount,
    required this.onComplete,
  });

  @override
  State<WorkoutLoggerSheet> createState() => _WorkoutLoggerSheetState();
}

class _WorkoutLoggerSheetState extends State<WorkoutLoggerSheet> {
  // These represent the actual performed sets
  late List<SetDetail> _loggedSets;

  @override
  void initState() {
    super.initState();
    // Initialize with empty sets (0 reps/0 weight) or copy defaults if we passed them
    _loggedSets = List.generate(
      widget.targetSetCount,
      (index) => SetDetail(reps: 0, weight: 0.0),
    );
    if (_loggedSets.isEmpty) _loggedSets.add(SetDetail());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.exerciseName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Finish and mark exercise as complete
                  widget.onComplete(true);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Finish",
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Labels
          Row(
            children: [
              const SizedBox(width: 40),
              const Spacer(),
              _label("kg"),
              const SizedBox(width: 20),
              _label("Reps"),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),

          // List
          Expanded(
            child: ListView.separated(
              itemCount: _loggedSets.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) =>
                  _buildLogRows(index + 1, _loggedSets[index], isDark),
            ),
          ),

          // Add Set
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 10,
            ),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  final last = _loggedSets.isNotEmpty
                      ? _loggedSets.last
                      : SetDetail();
                  _loggedSets.add(
                    SetDetail(reps: last.reps, weight: last.weight),
                  );
                });
              },
              icon: const Icon(Icons.add, color: Colors.deepOrange),
              label: const Text(
                "Add Set",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String txt) {
    return SizedBox(
      width: 80,
      child: Center(
        child: Text(
          txt,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogRows(int setNum, SetDetail set, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$setNum",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const Spacer(),
        // Weight Input
        _input(isDark, (val) => set.weight = double.tryParse(val) ?? 0),
        const SizedBox(width: 20),
        // Reps Input
        _input(isDark, (val) => set.reps = int.tryParse(val) ?? 0),
        // Delete
        SizedBox(
          width: 40,
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () => setState(() {
              if (_loggedSets.length > 1) _loggedSets.remove(set);
            }),
          ),
        ),
      ],
    );
  }

  Widget _input(bool isDark, Function(String) onChange) {
    return SizedBox(
      width: 80,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintText: "-",
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        ),
        onChanged: onChange,
      ),
    );
  }
}
