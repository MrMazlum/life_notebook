import 'package:flutter/material.dart';

class WeightPickerDialog extends StatefulWidget {
  final double initialWeight;
  final Function(double) onWeightChanged;

  const WeightPickerDialog({
    super.key,
    required this.initialWeight,
    required this.onWeightChanged,
  });

  @override
  State<WeightPickerDialog> createState() => _WeightPickerDialogState();
}

class _WeightPickerDialogState extends State<WeightPickerDialog> {
  late double _currentWeight;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight > 0 ? widget.initialWeight : 70.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Colors.deepPurpleAccent;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Update Weight",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentWeight.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "kg",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.2),
                thumbColor: color,
                overlayColor: color.withOpacity(0.1),
              ),
              child: Slider(
                value: _currentWeight,
                min: 30.0,
                max: 150.0,
                divisions: 1200,
                label: _currentWeight.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() => _currentWeight = val);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFineTuneBtn(Icons.remove, () {
                  setState(() => _currentWeight -= 0.1);
                }, isDark),
                _buildFineTuneBtn(Icons.add, () {
                  setState(() => _currentWeight += 0.1);
                }, isDark),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onWeightChanged(
                    double.parse(_currentWeight.toStringAsFixed(1)),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Entry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFineTuneBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}
