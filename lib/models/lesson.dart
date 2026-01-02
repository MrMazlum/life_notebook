class Lesson {
  String name;
  String startTime; // Format: "09:00"
  int durationMinutes; // New! Instead of endTime string, we store minutes (e.g. 45)
  String room;
  String instructor;
  
  Lesson({
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    required this.room,
    required this.instructor,
  });

  // Helper: Calculates "10:30" based on "09:00" + 90 mins
  String getEndTimeString() {
    try {
      final parts = startTime.split(':');
      final startHour = int.parse(parts[0]);
      final startMinute = int.parse(parts[1]);

      // Create a date object (using today) to do the math easily
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day, startHour, startMinute);
      
      // Add duration
      final endDate = startDate.add(Duration(minutes: durationMinutes));

      // Format back to HH:MM string
      final endHour = endDate.hour.toString().padLeft(2, '0');
      final endMinute = endDate.minute.toString().padLeft(2, '0');
      
      return '$endHour:$endMinute';
    } catch (e) {
      return '??:??';
    }
  }
}