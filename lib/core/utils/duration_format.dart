import '../../l10n/l10n.dart';

/// Formats a duration in minutes as a human-readable string.
///
/// Units: years (y), months (M), days (d), hours (h), minutes (m).
/// Ratios: 60m = 1h, 24h = 1d, 30d = 1M, 12M = 1y.
/// Only units from the highest reached scale down to minutes are shown
/// (e.g. 55h → "2d 7h 0m", with no years or months).
String formatDurationMinutes(int minutes, {AppLocalizations? l10n}) {
  final strings = l10n ?? AppL10n.current;
  if (minutes <= 0) return strings.durationZeroMinutes;

  const minutesPerHour = 60;
  const minutesPerDay = 24 * minutesPerHour;
  const minutesPerMonth = 30 * minutesPerDay;
  const minutesPerYear = 12 * minutesPerMonth;

  var remaining = minutes;
  final years = remaining ~/ minutesPerYear;
  remaining %= minutesPerYear;
  final months = remaining ~/ minutesPerMonth;
  remaining %= minutesPerMonth;
  final days = remaining ~/ minutesPerDay;
  remaining %= minutesPerDay;
  final hours = remaining ~/ minutesPerHour;
  final mins = remaining % minutesPerHour;

  final parts = <String>[];

  if (years > 0) {
    parts.add(strings.durationYears(years));
    parts.add(strings.durationMonths(months));
    parts.add(strings.durationDays(days));
    parts.add(strings.durationHours(hours));
    parts.add(strings.durationMinutes(mins));
  } else if (months > 0) {
    parts.add(strings.durationMonths(months));
    parts.add(strings.durationDays(days));
    parts.add(strings.durationHours(hours));
    parts.add(strings.durationMinutes(mins));
  } else if (days > 0) {
    parts.add(strings.durationDays(days));
    parts.add(strings.durationHours(hours));
    parts.add(strings.durationMinutes(mins));
  } else if (hours > 0) {
    parts.add(strings.durationHours(hours));
    parts.add(strings.durationMinutes(mins));
  } else {
    parts.add(strings.durationMinutes(mins));
  }

  return parts.join(' ');
}

/// Whole hours contained in [minutes] (60 minutes = 1 hour).
int totalHoursFromMinutes(int minutes) => minutes <= 0 ? 0 : minutes ~/ 60;

/// Whether [minutes] reaches at least one full day (24 hours).
bool isAtLeastOneDay(int minutes) => minutes >= 24 * 60;

/// Low-emphasis hours-only summary, e.g. "that's 55 hours".
String formatHoursOnlyHint(int minutes, {AppLocalizations? l10n}) {
  final strings = l10n ?? AppL10n.current;
  final hours = totalHoursFromMinutes(minutes);
  return hours == 1
      ? strings.hoursOnlyHintOne
      : strings.hoursOnlyHintOther(hours);
}
