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
  // Page 1000 represents the "Current Week" (relative to DateTime.now())
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    // Calculate the initial page based on the selectedDate passed in
    final initialIndex = _calculatePageForDate(widget.selectedDate);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(covariant CalendarHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent updates the date (e.g. via the Month Picker), snap the strip to that week
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

  /// Calculates how many weeks `date` is away from "This Week"
  int _calculatePageForDate(DateTime date) {
    final now = DateTime.now();
    // Normalize both to UTC or start of day to avoid timezone issues,
    // but simplified here: find the Monday of both weeks.
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

  Future<void> _showCalendarPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = isDark ? Colors.deepPurpleAccent : primaryColor;

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
      // The didUpdateWidget method will handle the page jump
    }
  }

  void _onArrowTap(int direction) {
    _pageController.animateToPage(
      _pageController.page!.round() + direction,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  DateTime _getMondayForPage(int index) {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final weeksDiff = index - _initialPage;
    return currentMonday.add(Duration(days: weeksDiff * 7));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final highlightColor = isDark
        ? Colors.deepPurpleAccent
        : Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  if (DateFormat('yyyy-MM-dd').format(widget.selectedDate) !=
                      DateFormat('yyyy-MM-dd').format(DateTime.now()))
                    IconButton(
                      onPressed: () => widget.onDateSelected(DateTime.now()),
                      icon: Icon(
                        Icons.turn_slight_left,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      tooltip: "Jump to Today",
                    ),
                ],
              ),
              IconButton(
                onPressed: () => _showCalendarPicker(context),
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: highlightColor,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 65,
            child: Row(
              children: [
                InkWell(
                  onTap: () => _onArrowTap(-1),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      final mondayOfNewPage = _getMondayForPage(index);
                      // Keep the same "Day of Week" (e.g. if I was on Tuesday, stay on Tuesday)
                      final currentWeekdayOffset =
                          widget.selectedDate.weekday - 1;
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
                        children: weekDays
                            .map(
                              (date) =>
                                  _buildDayItem(date, highlightColor, isDark),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
                InkWell(
                  onTap: () => _onArrowTap(1),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? highlightColor
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
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
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.grey,
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
