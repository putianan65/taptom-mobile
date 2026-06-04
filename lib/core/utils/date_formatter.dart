
class DateFormatter {
  static const List<String> thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
  
  static String formatThaiDate(DateTime? date) {
    if (date == null) return 'เลือกวันที่';
    return '${date.day} ${thaiMonthsShort[date.month - 1]} ${date.year + 543}';
  }
  
  static String formatThaiDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่ระบุ';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '${formatThaiDate(dateTime)} เวลา $time น.';
  }
}
