import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/dashboard_models.dart';

class FinanceCard extends StatelessWidget {
  final VoidCallback onNavigate;
  const FinanceCard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = Colors.green;
    final user = FirebaseAuth.instance.currentUser;

    // 1. Listen to User Settings (for Currency)
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots()
          : null,
      builder: (context, userSnap) {
        // Default to Euro if not set
        String currencySymbol = '€';
        if (userSnap.hasData &&
            userSnap.data!.exists &&
            userSnap.data!.data() != null) {
          final data = userSnap.data!.data() as Map<String, dynamic>;
          if (data.containsKey('currencySymbol')) {
            currencySymbol = data['currencySymbol'];
          }
        }

        // 2. Listen to Spending Data
        return StreamBuilder<double>(
          stream: DashboardModel().getDailySpend(),
          builder: (context, snapshot) {
            double spent = snapshot.data ?? 0.00;
            double budget =
                50.00; // You might want to fetch this from DB too later
            double progress = (spent / budget).clamp(0.0, 1.0);

            return Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border(bottom: BorderSide(color: accent, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // CHANGED: Use a neutral wallet icon instead of dollar sign ($)
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "WALLET",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      _buildArrowButton(accent, onNavigate),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CHANGED: Use the dynamic currency symbol
                      Text(
                        "$currencySymbol${spent.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "Spent Today",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.grey.withOpacity(0.2),
                    color: accent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArrowButton(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
      ),
    );
  }
}
