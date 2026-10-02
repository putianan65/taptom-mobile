/// Thai calendar helpers. The UI shows Buddhist-era years; the API speaks
/// Gregorian ISO dates.
abstract final class ThaiDate {
  static const monthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  static const monthsLong = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  /// Builds a date from separate day, month and year fields. Accepts both
  /// Buddhist-era (2400+) and Gregorian years. Returns null for impossible
  /// dates such as 31 February or dates in the future.
  static DateTime? parseParts(String day, String month, String year) {
    final d = int.tryParse(day.trim());
    final m = int.tryParse(month.trim());
    var y = int.tryParse(year.trim());
    if (d == null || m == null || y == null) return null;
    if (y > 2400) y -= 543;
    if (y < 1900 || m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    if (date.month != m || date.day != d) return null;
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  static String toIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 5 ม.ค. 2569
  static String short(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.day} ${monthsShort[local.month - 1]} ${local.year + 543}';
  }

  /// 5 มกราคม 2569
  static String long(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.day} ${monthsLong[local.month - 1]} ${local.year + 543}';
  }

  /// 5 ม.ค. 2569, 14:05 น.
  static String withTime(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${short(local)}, $hh:$mm น.';
  }

  /// "เมื่อสักครู่", "5 นาทีที่แล้ว", "เมื่อวาน" or a short date.
  static String relative(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final ref = now ?? DateTime.now();
    final diff = ref.difference(date.toLocal());
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays == 1) return 'เมื่อวาน';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return short(date);
  }

  /// Greeting for the current time of day.
  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 11) return 'สวัสดีตอนเช้า';
    if (h < 13) return 'สวัสดีตอนเที่ยง';
    if (h < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }
}
