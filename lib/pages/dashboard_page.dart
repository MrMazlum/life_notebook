import 'dart:async';
import 'dart:ui'; // Needed for FontFeature
import 'package:flutter/material.dart';
import '../widgets/dashboard/schedule_card.dart';
import '../widgets/dashboard/finance_card.dart';
import '../widgets/dashboard/book_card.dart';
import '../widgets/dashboard/health_card.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _timer;
  String _timeString = "00:00:00";

  @override
  void initState() {
    super.initState();
    _startClock();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final DateTime now = DateTime.now();
      final String formatted =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      if (mounted) {
        setState(() {
          _timeString = formatted;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Column(
              children: [
                // --- OLD-SCHOOL DIGITAL CLOCK LOOK ---
                Text(
                  _timeString,
                  style: TextStyle(
                    fontSize: 62,
                    // Max thickness to make it look "blocky"
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    // Monospace gives it the "cornered" digital typewriter feel
                    fontFamily: 'monospace',
                    // Negative spacing tightens it up like an LCD screen
                    letterSpacing: -4.0,
                    height: 1.0,
                    // Ensures numbers don't jump around
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Friday, January 9",
                  style: TextStyle(
                    fontSize: 18,
                    color: textPrimary.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            ScheduleCard(onNavigate: () => widget.onNavigate(4)),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FinanceCard(onNavigate: () => widget.onNavigate(3)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BookCard(onNavigate: () => widget.onNavigate(1)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            HealthCard(onNavigate: () => widget.onNavigate(0)),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
