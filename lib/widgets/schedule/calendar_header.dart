import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarHeader({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  late PageController _pageController;

  // We use a large initial page index so the user can swipe "back" infinitely
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper to trigger the "Red Area" Date Picker with Custom Dark Theme
  Future<void> _showCalendarPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              headerBackgroundColor: accentColor,
              headerForegroundColor: Colors.white,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: Theme.of(context).brightness,
              primary: accentColor,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateSelected(picked);
      // Reset page view to center when picking a far-away date manually
      _pageController.jumpToPage(_initialPage);
    }
  }

  void _onArrowTap(int direction) {
    _pageController.animateToPage(
      _pageController.page!.round() + direction,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic, // The "smooth" curve
    );
  }

  // Calculates the Monday for a specific page index
  DateTime _getMondayForPage(int index) {
    // Current Monday
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));

    // Calculate difference from initial page
    final weeksDiff = index - _initialPage;
    return currentMonday.add(Duration(days: weeksDiff * 7));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    // Use the primary color in light mode, deepPurpleAccent in dark mode
    final highlightColor = isDark ? Colors.deepPurpleAccent : primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // --- TOP ROW (Date Text & Calendar Icon) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT SIDE: Month Name + "Back to Today" button
              Row(
                children: [
                  Text(
                    DateFormat('MMMM d').format(widget.selectedDate),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      widget.onDateSelected(DateTime.now());
                      _pageController.animateToPage(
                        _initialPage,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.turn_slight_left,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    tooltip: "Jump to Today",
                  ),
                ],
              ),
              // RIGHT SIDE: Calendar Picker Icon
              IconButton(
                onPressed: () => _showCalendarPicker(context),
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: highlightColor,
                  size: 28,
                ),
                tooltip: "Select Month/Year",
              ),
            ],
          ),

          const SizedBox(height: 15),

          // --- SMOOTH WEEK SLIDER ---
          // FIX: Changed height from 80 to 65 to make buttons slimmer
          SizedBox(
            height: 65,
            child: Row(
              children: [
                // LEFT ARROW
                InkWell(
                  onTap: () => _onArrowTap(-1),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: isDark ? Colors.white54 : Colors.grey,
                      size: 28,
                    ),
                  ),
                ),

                // THE ANIMATED PAGE VIEW (The Days)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      // When user swipes, update the SELECTED date to maintain the same day-of-week
                      final mondayOfNewPage = _getMondayForPage(index);

                      // Calculate current offset (e.g., 0 for Monday, 1 for Tuesday)
                      final currentWeekdayOffset =
                          widget.selectedDate.weekday - 1;

                      // Calculate new date
                      final newDate = mondayOfNewPage.add(
                        Duration(days: currentWeekdayOffset),
                      );
                      widget.onDateSelected(newDate);
                    },
                    itemBuilder: (context, index) {
                      final monday = _getMondayForPage(index);
                      final weekDays = List.generate(
                        7,
                        (i) => monday.add(Duration(days: i)),
                      );

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekDays.map((date) {
                          final isSelected =
                              date.year == widget.selectedDate.year &&
                              date.month == widget.selectedDate.month &&
                              date.day == widget.selectedDate.day;

                          final now = DateTime.now();
                          final isToday =
                              date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onDateSelected(date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                // FIX: Reduced vertical padding to fit new height
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? highlightColor
                                      : (isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isToday && !isSelected
                                      ? Border.all(
                                          color: highlightColor.withOpacity(
                                            0.5,
                                          ),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'E',
                                      ).format(date).substring(0, 3),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white54
                                                  : Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      date.day.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                // RIGHT ARROW
                InkWell(
                  onTap: () => _onArrowTap(1),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white54 : Colors.grey,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
