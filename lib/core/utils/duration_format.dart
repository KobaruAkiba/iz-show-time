/// Formats a duration in minutes as a human-readable string (e.g. "2h 15m").
String formatDurationMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours > 0 && remaining > 0) return '${hours}h ${remaining}m';
  if (hours > 0) return '${hours}h';
  return '${remaining}m';
}
