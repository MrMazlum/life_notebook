import 'package:flutter/material.dart';
import 'exercise_models.dart';

class SetEditorSheet extends StatefulWidget {
  final String exerciseName;
  final List<SetDetail> initialSets;
  final Function(List<SetDetail>) onSave;

  const SetEditorSheet({
    super.key,
    required this.exerciseName,
    required this.initialSets,
    required this.onSave,
  });

  @override
  State<SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<SetEditorSheet> {
  late List<SetDetail> _sets;

  @override
  void initState() {
    super.initState();
    _sets = widget.initialSets
        .map((s) => SetDetail(reps: s.reps, weight: s.weight))
        .toList();
    if (_sets.isEmpty) _sets.add(SetDetail());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // 1. FORCE HEIGHT
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
                  widget.onSave(_sets);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
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

          // TABLE HEADERS
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    "Set",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 90,
                child: Center(
                  child: Text(
                    "kg",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 90,
                child: Center(
                  child: Text(
                    "Reps",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),

          // SCROLLABLE LIST
          Expanded(
            child: ListView.builder(
              itemCount: _sets.length,
              itemBuilder: (ctx, index) =>
                  _buildSetRow(index + 1, _sets[index], isDark),
            ),
          ),

          // BUTTON AREA
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    final lastSet = _sets.last;
                    _sets.add(
                      SetDetail(reps: lastSet.reps, weight: lastSet.weight),
                    );
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Set",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.black26
                      : Colors.grey.shade100,
                  foregroundColor: Colors.deepOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int number, SetDetail set, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Set Number Bubble
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$number",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Weight Input
          _buildCompactInput(
            set.weight.toString(),
            (val) => set.weight = double.tryParse(val) ?? set.weight,
            isDark,
          ),
          const SizedBox(width: 16),

          // Reps Input
          _buildCompactInput(
            set.reps.toString(),
            (val) => set.reps = int.tryParse(val) ?? set.reps,
            isDark,
          ),

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
                if (_sets.length > 1) _sets.remove(set);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput(
    String initial,
    Function(String) onChanged,
    bool isDark,
  ) {
    return SizedBox(
      width: 90,
      child: TextFormField(
        initialValue: initial,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
