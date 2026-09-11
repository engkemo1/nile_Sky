import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';

/// Centralized Date & Time Formatter for NileSky
/// Handles dynamic backend ISO dates (e.g. '2026-09-02', '2026-09-03T04:15:00.000Z')
/// and formats them dynamically according to the active locale (EN, AR, DE, FR, ES).
class DateHelper {
  /// Formats an ISO date string (from backend) into a localized, user-friendly string
  /// Example in AR: "غداً (الأربعاء، 3 سبتمبر 2026)" or "السبت، 12 سبتمبر 2026"
  /// Example in EN: "Tomorrow (Wednesday, Sep 3, 2026)" or "Saturday, Sep 12, 2026"
  static String formatFlightDate(
    BuildContext context,
    String? isoDateStr, {
    bool includeRelative = true,
  }) {
    if (isoDateStr == null || isoDateStr.trim().isEmpty) {
      return context.tr('tomorrow');
    }

    try {
      DateTime date;
      if (isoDateStr.toLowerCase() == 'tomorrow') {
        date = DateTime.now().add(const Duration(days: 1));
      } else if (isoDateStr.toLowerCase() == 'today') {
        date = DateTime.now();
      } else {
        date = DateTime.parse(isoDateStr);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final differenceInDays = target.difference(today).inDays;

      final locale = LanguageService.currentLanguageCode;
      final weekday = DateFormat.EEEE(locale).format(date);
      final formattedDayMonthYear = DateFormat.yMMMMd(locale).format(date);

      if (includeRelative) {
        if (differenceInDays == 0) {
          return '${context.tr('today')} ($weekday، $formattedDayMonthYear)';
        } else if (differenceInDays == 1) {
          return '${context.tr('tomorrow')} ($weekday، $formattedDayMonthYear)';
        }
      }

      return '$weekday، $formattedDayMonthYear';
    } catch (_) {
      return isoDateStr;
    }
  }

  /// Format standard departure time (e.g. '06:15') into localized string with AM/PM
  static String formatTime(BuildContext context, String timeStr) {
    if (timeStr.isEmpty) return '06:15 AM';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final dummyDate = DateTime(2026, 1, 1, hour, minute);
      final locale = LanguageService.currentLanguageCode;
      return DateFormat.jm(locale).format(dummyDate);
    } catch (_) {
      return timeStr;
    }
  }

  /// Pick a dynamic flight date with native Flutter DatePicker
  static Future<DateTime?> pickFlightDate({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final firstAllowed = now;
    final lastAllowed = now.add(const Duration(days: 180)); // 6 months ahead

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now.add(const Duration(days: 1)),
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      locale: Locale(LanguageService.currentLanguageCode),
    );
  }

  /// Converts DateTime object to Backend API ISO string (e.g. '2026-09-03')
  static String toApiDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
