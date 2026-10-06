import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/app/routes.dart';
import 'package:taptom/data/models/user_model.dart';

void main() {
  group('Routes.homeFor', () {
    test('sends each role to its own home', () {
      expect(Routes.homeFor(UserRole.farmer), Routes.farmerHome);
      expect(Routes.homeFor(UserRole.admin), Routes.adminHome);
      expect(Routes.homeFor(UserRole.superAdmin), Routes.superHome);
    });
  });

  group('Routes.rolesFor', () {
    test('super admin area is restricted to super admins', () {
      expect(Routes.rolesFor('/super-admin/logs'), {UserRole.superAdmin});
    });

    test('admin area is open to admins and super admins only', () {
      final roles = Routes.rolesFor('/admin/messages/42')!;
      expect(roles, contains(UserRole.admin));
      expect(roles, contains(UserRole.superAdmin));
      expect(roles, isNot(contains(UserRole.farmer)));
    });

    test('farmer home is farmer only', () {
      expect(Routes.rolesFor(Routes.farmerHome), {UserRole.farmer});
    });

    test('shared pages have no role restriction', () {
      expect(Routes.rolesFor(Routes.notifications), isNull);
      expect(Routes.rolesFor(Routes.supportTickets), isNull);
    });
  });

  test('traceability is public', () {
    expect(Routes.isPublic('/traceability/TPT-2569-0001'), isTrue);
    expect(Routes.isPublic(Routes.adminHome), isFalse);
  });
}
