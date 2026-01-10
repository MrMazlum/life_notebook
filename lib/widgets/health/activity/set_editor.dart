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
  // We use a local list to edit freely before saving
  late List<SetDetail> _sets;

  @override
  void initState() {
    super.initState();
    // Deep copy to prevent modifying the parent state directly until "Save" is pressed
    _sets = widget.initialSets
        .map((s) => SetDetail(reps: s.reps, weight: s.weight))
        .toList();

    // Ensure at least one set exists
    if (_sets.isEmpty) _sets.add(SetDetail());
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

          // Headers
          Row(
            children: [
              const SizedBox(width: 40), // Spacing for Index Bubble
              const Spacer(),
              _buildHeaderLabel("kg"),
              const SizedBox(width: 20),
              _buildHeaderLabel("Reps"),
              const SizedBox(width: 40), // Spacing for Delete Icon
            ],
          ),
          const SizedBox(height: 10),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: _sets.length,
              itemBuilder: (ctx, index) =>
                  _buildSetRow(index + 1, _sets[index], isDark),
            ),
          ),

          // Add Set Button
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
                    // Duplicate last set values for convenience
                    final last = _sets.last;
                    _sets.add(SetDetail(reps: last.reps, weight: last.weight));
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

  Widget _buildHeaderLabel(String text) {
    return SizedBox(
      width: 80,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSetRow(int number, SetDetail set, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Index Bubble
          Container(
            width: 40,
            height: 40,
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
          const Spacer(),

          // Weight
          _buildInput(isDark, set.weight.toString(), (val) {
            set.weight = double.tryParse(val) ?? 0;
          }),
          const SizedBox(width: 20),

          // Reps
          _buildInput(isDark, set.reps.toString(), (val) {
            set.reps = int.tryParse(val) ?? 0;
          }),

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

  Widget _buildInput(bool isDark, String initial, Function(String) onChanged) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: initial,
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
        ),
        onChanged: onChanged,
      ),
    );
  }
}
