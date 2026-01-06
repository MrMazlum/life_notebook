import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceHeader extends StatelessWidget {
  final DateTime selectedDate;
  final Function(int) onMonthChanged;
  final VoidCallback onResetDate;
  final bool isInspectingPast;
  final bool showChart;
  final Function(bool) onChartToggle;

  const FinanceHeader({
    super.key,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onResetDate,
    required this.isInspectingPast,
    required this.showChart,
    required this.onChartToggle,
  });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return selectedDate.year == now.year && selectedDate.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. LEFT: Back Button (Always Visible)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  if (_isCurrentMonth) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You are already up to date!"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    onResetDate();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.undo_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),

            // 2. CENTER: Month Navigator
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: const Offset(0, -4), // FIX: Shifts text up by 4 pixels
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: () => onMonthChanged(-1),
                      color: subTextColor,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Budget",
                          style: TextStyle(fontSize: 10, color: subTextColor),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      onPressed: () => onMonthChanged(1),
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),

            // 3. RIGHT: Toggle Buttons (Only if visible)
            if (_isCurrentMonth || isInspectingPast)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleBtn(
                        Icons.pie_chart_rounded,
                        true,
                        isDark,
                        primaryColor,
                      ),
                      _buildToggleBtn(
                        Icons.view_list_rounded,
                        false,
                        isDark,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(
    IconData icon,
    bool isChartTarget,
    bool isDark,
    Color activeColor,
  ) {
    final isSelected = showChart == isChartTarget;
    return GestureDetector(
      onTap: () => onChartToggle(isChartTarget),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white54 : Colors.black54),
        ),
      ),
    );
  }
}
