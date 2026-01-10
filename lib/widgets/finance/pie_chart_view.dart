import 'dart:math';
import 'package:flutter/material.dart';

// --- THIS CLASS WAS MISSING ---
class ChartData {
  final String id;
  final String name;
  final double amount;
  final Color color;
  final IconData icon;

  ChartData(this.id, this.name, this.amount, this.color, this.icon);
}
// ------------------------------

class PieChartView extends StatelessWidget {
  final double totalSpent;
  final List<ChartData> data;
  final String currencySymbol;
  final Function(String) onSectionTap;

  const PieChartView({
    super.key,
    required this.totalSpent,
    required this.data,
    required this.currencySymbol,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. The Interactive Donut Chart
          GestureDetector(
            onTapUp: (details) {
              _handleTap(details, context);
            },
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _DonutChartPainter(
                      data: data,
                      total: totalSpent,
                      bgColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  // Center Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$currencySymbol${totalSpent.toInt()}",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. The Legend
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: data.map((item) {
              final percent = totalSpent == 0
                  ? 0
                  : (item.amount / totalSpent * 100).toInt();
              return GestureDetector(
                onTap: () => onSectionTap(item.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 18, color: item.color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "$percent%",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details, BuildContext context) {
    if (totalSpent == 0) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    final Offset center = Offset(box.size.width / 2, 180 / 2);
    final dx = localOffset.dx - center.dx;
    final dy = localOffset.dy - center.dy;
    double angle = atan2(dy, dx);
    angle += pi / 2;
    if (angle < 0) angle += 2 * pi;

    double currentAngle = 0;
    for (var item in data) {
      final sweepAngle = (item.amount / totalSpent) * 2 * pi;
      if (angle >= currentAngle && angle < currentAngle + sweepAngle) {
        onSectionTap(item.id);
        return;
      }
      currentAngle += sweepAngle;
    }
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double total;
  final Color bgColor;

  _DonutChartPainter({
    required this.data,
    required this.total,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 20.0;
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (total == 0) return;

    double startAngle = -pi / 2;
    for (var item in data) {
      final sweepAngle = (item.amount / total) * 2 * pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (sweepAngle > 0) {
        final gap = data.length > 1 ? 0.05 : 0.0;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle + gap / 2,
          sweepAngle - gap,
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
