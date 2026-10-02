import 'thai_date.dart';

/// Kept for existing call sites; prefer [ThaiDate] in new code.
abstract final class DateFormatter {
  static const List<String> thaiMonthsShort = ThaiDate.monthsShort;

  static String formatThaiDate(DateTime? date) =>
      date == null ? 'เลือกวันที่' : ThaiDate.short(date);

  static String formatThaiDateTime(DateTime? dateTime) =>
      dateTime == null ? 'ไม่ระบุ' : ThaiDate.withTime(dateTime);
}
