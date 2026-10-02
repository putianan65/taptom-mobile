/// Accounts recognised by the demo backend. Only used when the app is built
/// with `--dart-define=TAPTOM_DEMO=true`.
class DemoAccount {
  const DemoAccount({
    required this.label,
    required this.phone,
    required this.day,
    required this.month,
    required this.yearBE,
    required this.role,
  });

  final String label;
  final String phone;
  final String day;
  final String month;
  final String yearBE;
  final String role;

  /// Birthday as the sign-in API expects it (Gregorian ISO date).
  String get isoBirthday =>
      '${int.parse(yearBE) - 543}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
}

abstract final class DemoAccounts {
  /// PIN for the demo officer. Super admins use eight digits.
  static const pin = '123456';
  static const superPin = '12345678';

  static const farmer = DemoAccount(
    label: 'เกษตรกร',
    phone: '0812345678',
    day: '15',
    month: '01',
    yearBE: '2518',
    role: 'USER',
  );

  static const admin = DemoAccount(
    label: 'เจ้าหน้าที่',
    phone: '0898765432',
    day: '20',
    month: '05',
    yearBE: '2528',
    role: 'ADMIN',
  );

  static const superAdmin = DemoAccount(
    label: 'ผู้ดูแลระบบ',
    phone: '0800000001',
    day: '01',
    month: '01',
    yearBE: '2525',
    role: 'SUPER_ADMIN',
  );

  static const all = [farmer, admin, superAdmin];
}
