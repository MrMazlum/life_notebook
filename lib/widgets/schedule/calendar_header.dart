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
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculatePageForDate(widget.selectedDate);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(covariant CalendarHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      final targetPage = _calculatePageForDate(widget.selectedDate);
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    final mondayNow = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = date.subtract(Duration(days: date.weekday - 1));
    final diff = mondayDate.difference(mondayNow).inDays;
    final weeksDiff = (diff / 7).round();
    return _initialPage + weeksDiff;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMondayForPage(int index) {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final weeksDiff = index - _initialPage;
    return currentMonday.add(Duration(days: weeksDiff * 7));
  }

  Future<void> _showCalendarPicker(
    BuildContext context,
    Color accentColor,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: accentColor,
              headerForegroundColor: Colors.white,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onDateSelected(picked);
    }
  }

  void _handleBackToToday(Color themeColor) {
    if (DateUtils.isSameDay(widget.selectedDate, DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You are already up to date!"),
          backgroundColor: themeColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      widget.onDateSelected(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final themeColor = isDark
        ? Colors.deepPurpleAccent
        : Theme.of(context).primaryColor;

    return Column(
      children: [
        const SizedBox(height: 20), // Top Spacing
        // --- TOP ROW ---
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
          ), // STRICT MARGIN
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. LEFT: Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _handleBackToToday(themeColor),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.undo_rounded,
                        color: themeColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // 2. CENTER: Date Text
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat('MMMM d').format(widget.selectedDate),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                // 3. RIGHT: Calendar Picker
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _showCalendarPicker(context, themeColor),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: themeColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20), // Vertical Gap between Title and Days
        // --- BOTTOM ROW: Week Strip ---
        SizedBox(
          height: 70, // Standard height
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final mondayOfNewPage = _getMondayForPage(index);
              final currentWeekdayOffset = widget.selectedDate.weekday - 1;
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

              // Padding applied inside here matches the Top Row padding (20.0)
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays
                      .map((date) => _buildDayItem(date, themeColor, isDark))
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(DateTime date, Color highlightColor, bool isDark) {
    final isSelected =
        date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onDateSelected(date),
        child: Container(
          // Margin to separate bubbles
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? highlightColor
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: isToday && !isSelected
                ? Border.all(color: highlightColor.withOpacity(0.5))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E').format(date).substring(0, 3),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
