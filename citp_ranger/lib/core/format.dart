import 'package:intl/intl.dart';

String formatDate(DateTime value) {
  return DateFormat('d MMM yyyy').format(value.toLocal());
}

String formatDateTime(DateTime value) {
  return DateFormat('d MMM yyyy, HH:mm').format(value.toLocal());
}

String formatPoint(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return 'No fix';
  final latHemisphere = latitude < 0 ? 'S' : 'N';
  final lngHemisphere = longitude < 0 ? 'W' : 'E';
  return '${latitude.abs().toStringAsFixed(5)}° $latHemisphere    ${longitude.abs().toStringAsFixed(5)}° $lngHemisphere';
}

String followUpLabel(DateTime due, DateTime now) {
  final dueDay = _dateOnly(due.toLocal());
  final today = _dateOnly(now.toLocal());
  final days = dueDay.difference(today).inDays;
  if (days < 0) {
    final count = -days;
    return count == 1 ? '1 day overdue' : '$count days overdue';
  }
  if (days == 0) return 'Re-check today';
  if (days == 1) return 'Re-check tomorrow';
  return 'Re-check in $days days';
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
