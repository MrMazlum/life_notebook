import 'package:flutter/material.dart';
import '../widgets/dashboard/schedule_card.dart';
import '../widgets/dashboard/finance_card.dart';
import '../widgets/dashboard/book_card.dart';
import '../widgets/dashboard/health_card.dart';

class DashboardPage extends StatelessWidget {
  final Function(int) onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        // Added slightly more top padding since the clock is gone
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. UP NEXT / SCHEDULE
            ScheduleCard(onNavigate: () => onNavigate(4)),

            const SizedBox(height: 12),

            // 2. FINANCE & BOOKS ROW
            Row(
              children: [
                Expanded(child: FinanceCard(onNavigate: () => onNavigate(3))),
                const SizedBox(width: 16),
                Expanded(child: BookCard(onNavigate: () => onNavigate(1))),
              ],
            ),

            const SizedBox(height: 12),

            // 3. HEALTH CARD
            HealthCard(onNavigate: () => onNavigate(0)),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
