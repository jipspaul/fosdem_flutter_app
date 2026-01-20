import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  String toFormattedTime() {
    return DateFormat('HH:mm').format(this);
  }

  String toFormattedDateTime() {
    return DateFormat('yyyy-MM-dd HH:mm').format(this);
  }

  String toDisplayDate() {
    return DateFormat('EEEE, MMMM d, y').format(this);
  }

  String toDisplayTime() {
    return DateFormat('HH:mm').format(this);
  }

  String toDisplayDateTime() {
    return DateFormat('EEEE, MMMM d, y HH:mm').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(tomorrow);
  }

  String toRelativeTime() {
    final now = DateTime.now();
    final difference = this.difference(now);

    if (difference.isNegative) {
      return 'Past';
    } else if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return 'In ${difference.inDays} days';
    }
  }
}
