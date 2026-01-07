import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // HEADER
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),
            Text(
              "Today's Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // 1. HEALTH SUMMARY CARD
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('health_logs')
                  .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                  .snapshots(),
              builder: (context, snapshot) {
                int steps = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  steps = data['steps'] ?? 0;
                }
                return _buildSummaryCard(
                  context,
                  title: "Steps Taken",
                  value: "$steps",
                  subtitle: "Goal: 10,000",
                  icon: Icons.directions_walk,
                  color: Colors.orange,
                  progress: (steps / 10000).clamp(0.0, 1.0),
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. FINANCE SUMMARY CARD
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('finance_transactions')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                double balance = 0;
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] as num).toDouble();
                    final isExpense = data['isExpense'] as bool;
                    if (isExpense) {
                      balance -= amount;
                    } else {
                      balance += amount;
                    }
                  }
                }
                return _buildSummaryCard(
                  context,
                  title: "Wallet Balance",
                  value: "\$${balance.toStringAsFixed(2)}",
                  subtitle: "Total Savings",
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  progress: 1.0,
                  isFinance: true,
                );
              },
            ),

            const SizedBox(height: 16),

            // 3. SCHEDULE SUMMARY CARD
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int eventsToday = 0;
                if (snapshot.hasData) {
                  final nowString = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now());
                  final dayName = DateFormat('EEEE').format(DateTime.now());

                  eventsToday = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isRecurring = data['isRecurring'] as bool;
                    if (isRecurring) {
                      final exclude = List<String>.from(
                        data['excludeDates'] ?? [],
                      );
                      return data['dayOfWeek'] == dayName &&
                          !exclude.contains(nowString);
                    } else {
                      return data['specificDate'] == nowString;
                    }
                  }).length;
                }

                return _buildSummaryCard(
                  context,
                  title: "Schedule",
                  value: "$eventsToday Events",
                  subtitle: "Remaining Today",
                  icon: Icons.calendar_today,
                  color: Colors.deepPurple,
                  progress: 0.0,
                  hideProgress: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    bool isFinance = false,
    bool hideProgress = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                // --- FIX IS BELOW: added \ before $ ---
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isFinance && value.startsWith('\$-')
                        ? Colors.red
                        : textColor,
                  ),
                ),
                if (!hideProgress) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withValues(alpha: 0.1),
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
