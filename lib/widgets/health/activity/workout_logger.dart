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
  late List<SetDetail> _loggedSets;

  @override
  void initState() {
    super.initState();
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

    // FIX: Force height to 85% of screen so it doesn't get cut off
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
          // HANDLE
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

          // HEADER
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

          // COLUMN TITLES
          Row(
            children: [
              const SizedBox(width: 40), // Space for Set # badge
              const Spacer(),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    "kg",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    "Reps",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40), // Space for delete icon
            ],
          ),
          const SizedBox(height: 10),

          // SCROLLABLE LIST
          Expanded(
            child: ListView.separated(
              itemCount: _loggedSets.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) =>
                  _buildLogRows(index + 1, _loggedSets[index], isDark),
            ),
          ),

          // ADD SET BUTTON (Pinned to bottom of visible area)
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

  Widget _buildLogRows(int setNum, SetDetail set, bool isDark) {
    return Row(
      children: [
        // Set Badge
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
        // Weight
        _buildInput(isDark, (val) => set.weight = double.tryParse(val) ?? 0),
        const SizedBox(width: 20),
        // Reps
        _buildInput(isDark, (val) => set.reps = int.tryParse(val) ?? 0),
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

  Widget _buildInput(bool isDark, Function(String) onChange) {
    return SizedBox(
      width: 80,
      child: TextField(
        keyboardType: TextInputType.number,
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
