import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui'
    as ui; // <--- FIX: Explicit import to solve TextDirection error

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
  List<WeightPoint> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight > 0 ? widget.initialWeight : 70.0;
    _fetchWeightHistory();
  }

  Future<void> _fetchWeightHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_logs')
          .orderBy('date', descending: true)
          .limit(14)
          .get();

      final List<WeightPoint> points = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['weight'] != null && (data['weight'] as num) > 0) {
          final dateStr = data['date'] as String;
          final date = DateTime.parse(dateStr);
          final weight = (data['weight'] as num).toDouble();
          points.add(WeightPoint(date, weight));
        }
      }

      points.sort((a, b) => a.date.compareTo(b.date));

      final recentPoints = points.length > 7
          ? points.sublist(points.length - 7)
          : points;

      if (mounted) {
        setState(() {
          _history = recentPoints;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Colors.deepOrange;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Weight Tracker",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // GRAPH CONTAINER
            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isLoadingHistory
                  ? Center(child: CircularProgressIndicator(color: accentColor))
                  : _history.length < 2
                  ? Center(
                      child: Text(
                        "Add more entries to see trend",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : CustomPaint(
                      painter: WeightChartPainter(
                        points: _history,
                        color: accentColor,
                        isDark: isDark,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // CURRENT WEIGHT DISPLAY
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
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "kg",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            // SLIDER
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.2),
                thumbColor: accentColor,
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                overlayColor: accentColor.withOpacity(0.1),
              ),
              child: Slider(
                value: _currentWeight,
                min: 30.0,
                max: 150.0,
                divisions: 1200,
                onChanged: (val) => setState(() => _currentWeight = val),
              ),
            ),

            // FINE TUNE BUTTONS
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
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onWeightChanged(
                    double.parse(_currentWeight.toStringAsFixed(1)),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  "Update Weight",
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}

class WeightPoint {
  final DateTime date;
  final double value;
  WeightPoint(this.date, this.value);
}

class WeightChartPainter extends CustomPainter {
  final List<WeightPoint> points;
  final Color color;
  final bool isDark;

  WeightChartPainter({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minWeight = points.map((e) => e.value).reduce(min);
    double maxWeight = points.map((e) => e.value).reduce(max);

    double range = maxWeight - minWeight;
    if (range == 0) range = 10;
    double minY = minWeight - (range * 0.2);
    double maxY = maxWeight + (range * 0.2);

    final double w = size.width;
    final double h = size.height - 30;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = isDark ? Colors.white : color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        // <--- USING ui.Gradient
        Offset(0, 0),
        Offset(0, h),
        [color.withOpacity(0.3), color.withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final shadowPath = Path();

    List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      double x = (i / (points.length - 1)) * w;
      double normalizedY = (points[i].value - minY) / (maxY - minY);
      double y = h - (normalizedY * h);
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets[0].dx, offsets[0].dy);
    shadowPath.moveTo(offsets[0].dx, h);
    shadowPath.lineTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];

      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );

      shadowPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    shadowPath.lineTo(offsets.last.dx, h);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, linePaint);

    // Explicit usage of ui.TextDirection
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i < offsets.length; i++) {
      canvas.drawCircle(offsets[i], 4, dotPaint);

      bool shouldDrawLabel =
          i == 0 || i == offsets.length - 1 || i == offsets.length ~/ 2;

      if (shouldDrawLabel) {
        final dateText = DateFormat('MM/dd').format(points[i].date);
        textPainter.text = TextSpan(
          text: dateText,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(offsets[i].dx - (textPainter.width / 2), h + 10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
