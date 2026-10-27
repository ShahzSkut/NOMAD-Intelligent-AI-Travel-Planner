// Utility class for date formatting and calculations.
class AppDateUtils {
  static String formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}'
        .toUpperCase();
  }

  static String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  static int calculateDuration(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
}
