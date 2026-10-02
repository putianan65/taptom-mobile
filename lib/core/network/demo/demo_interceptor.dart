import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'demo_accounts.dart';
import 'demo_seed.dart';

/// Answers every API call from an in-memory backend so the app can run
/// without a server (`--dart-define=TAPTOM_DEMO=true`). Responses mirror the
/// real API's shapes and status codes, writes are kept for the session, and
/// a short random latency keeps loading states honest.
class DemoInterceptor extends Interceptor {
  DemoInterceptor() : _db = DemoBackend.instance;

  final DemoBackend _db;
  final _random = math.Random();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future.delayed(Duration(milliseconds: 180 + _random.nextInt(240)));
    try {
      final (status, body) = _db.handle(options);
      handler.resolve(
        Response(requestOptions: options, statusCode: status, data: body),
        true,
      );
    } on DemoHttpError catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: e.status,
            data: {'statusCode': e.status, 'message': e.message},
          ),
        ),
        true,
      );
    }
  }
}

class DemoHttpError implements Exception {
  DemoHttpError(this.status, this.message);

  final int status;
  final String message;
}

typedef _Handler = (int, dynamic) Function(_Req req);

class _Req {
  _Req(this.options, this.params, this.userId, this.role);

  final RequestOptions options;
  final List<String> params;
  final String? userId;
  final String? role;

  Map<String, dynamic> get query => options.queryParameters;

  Map<String, dynamic> get body {
    final d = options.data;
    if (d is Map) return Map<String, dynamic>.from(d);
    if (d is String && d.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(d) as Map);
      } catch (_) {}
    }
    return {};
  }

  String param(int i) => params[i];

  String requireUser() {
    final id = userId;
    if (id == null) throw DemoHttpError(401, 'Unauthorized');
    return id;
  }

  bool get isStaff => role == 'ADMIN' || role == 'SUPER_ADMIN';
}

/// The in-memory data store and route table.
class DemoBackend {
  DemoBackend._() {
    _seed();
    _routes = _buildRoutes();
  }

  static final instance = DemoBackend._();

  late final List<(String, RegExp, _Handler)> _routes;

  late List<Map<String, dynamic>> users;
  late List<Map<String, dynamic>> plots;
  late Map<String, Map<String, dynamic>> gap;
  late Map<String, List<Map<String, dynamic>>> inputs;
  late Map<String, List<Map<String, dynamic>>> activities;
  late Map<String, List<Map<String, dynamic>>> harvests;
  late Map<String, List<Map<String, dynamic>>> trainings;
  final Map<String, List<Map<String, dynamic>>> notifications = {};
  late List<Map<String, dynamic>> auditLogs;
  late List<Map<String, dynamic>> messages;
  late List<Map<String, dynamic>> tickets;
  int _seq = 1000;

  void _seed() {
    users = DemoSeed.users();
    plots = DemoSeed.plots();
    gap = DemoSeed.gapRecords();
    inputs = DemoSeed.inputs();
    activities = DemoSeed.activities();
    harvests = DemoSeed.harvests();
    trainings = DemoSeed.trainings();
    auditLogs = DemoSeed.auditLogs();
    messages = _seedMessages();
    tickets = _seedTickets();
  }

  String _id(String prefix) => '$prefix-${_seq++}';
  String _now() => DateTime.now().toUtc().toIso8601String();

  // Tokens -----------------------------------------------------------------

  static String token(String userId, String role, {String type = 'access'}) {
    String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    return '${b64({'alg': 'none'})}.${b64({'sub': userId, 'role': role, 'type': type})}.demo';
  }

  static Map<String, dynamic>? decode(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _session(Map<String, dynamic> user) => {
        'accessToken': token(user['id'], user['role']),
        'refreshToken': token(user['id'], user['role'], type: 'refresh'),
        'user': user,
      };

  // Lookups ----------------------------------------------------------------

  Map<String, dynamic> _user(String id) => users.firstWhere(
        (u) => u['id'] == id,
        orElse: () => throw DemoHttpError(404, 'User not found'),
      );

  Map<String, dynamic> _plot(String id) => plots.firstWhere(
        (p) => p['id'] == id && p['deletedAt'] == null,
        orElse: () => throw DemoHttpError(404, 'Plot not found'),
      );

  Map<String, dynamic> _owner(String userId) {
    final u = _user(userId);
    return {'id': u['id'], 'firstName': u['firstName'], 'lastName': u['lastName'], 'phone': u['phone']};
  }

  List<Map<String, dynamic>> _visiblePlots(_Req r) {
    final uid = r.requireUser();
    final live = plots.where((p) => p['deletedAt'] == null);
    if (r.role == 'USER') return live.where((p) => p['userId'] == uid).toList();
    return live.toList();
  }

  List<Map<String, dynamic>> _territory(_Req r) => users
      .where((u) => u['role'] == 'USER' && u['deletedAt'] == null)
      .toList();

  void _notify(String userId, String title, String message, String type, [Map<String, dynamic>? data]) {
    notifications.putIfAbsent(userId, () => DemoSeed.notifications(userId)).insert(0, {
      'id': _id('n'),
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': ?data,
      'isRead': false,
      'createdAt': _now(),
    });
  }

  void _audit(String? actor, String action, String type, String details) {
    final u = actor == null ? null : users.where((x) => x['id'] == actor).firstOrNull;
    auditLogs.insert(0, {
      'id': _id('log'),
      'action': action,
      'resourceType': type,
      'details': details,
      'userId': actor,
      'user': u == null
          ? null
          : {'firstName': u['firstName'], 'lastName': u['lastName'], 'role': u['role']},
      'createdAt': _now(),
    });
  }

  // Dispatch ---------------------------------------------------------------

  (int, dynamic) handle(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = Uri.parse(options.path).path.replaceFirst(RegExp(r'^/api/v1'), '');
    final auth = options.headers['Authorization']?.toString();
    final claims = decode(auth?.replaceFirst('Bearer ', ''));
    final userId = claims?['type'] == 'access' ? claims!['sub'] as String? : null;
    final role = userId == null
        ? null
        : users.where((u) => u['id'] == userId).firstOrNull?['role'] as String?;

    for (final (m, pattern, handler) in _routes) {
      if (m != method) continue;
      final match = pattern.firstMatch(path);
      if (match == null) continue;
      final params = [for (var i = 1; i <= match.groupCount; i++) Uri.decodeComponent(match.group(i)!)];
      return handler(_Req(options, params, userId, role));
    }
    throw DemoHttpError(404, 'Cannot $method $path');
  }

  List<(String, RegExp, _Handler)> _buildRoutes() {
    (String, RegExp, _Handler) r(String method, String pattern, _Handler h) =>
        (method, RegExp('^$pattern\$'), h);
    const id = r'([^/]+)';

    return [
      // Auth -----------------------------------------------------------------
      r('POST', '/auth/signin', (q) {
        final b = q.body;
        final account = DemoAccounts.all.where((a) => a.phone == b['phone']).firstOrNull;
        final user = users.where((u) => u['phone'] == b['phone']).firstOrNull;
        if (user == null) throw DemoHttpError(401, 'Invalid credentials');
        if (account != null && account.isoBirthday != b['birthday']) {
          throw DemoHttpError(401, 'Invalid credentials');
        }
        if (user['role'] != 'USER') {
          return (
            200,
            {
              'requiresPin': true,
              'tempToken': token(user['id'], user['role'], type: 'temp'),
              'message': 'Please enter your PIN to continue.',
            }
          );
        }
        return (200, _session(user));
      }),
      r('POST', '/auth/verify-pin', (q) {
        final claims = decode(q.body['tempToken'] as String?);
        if (claims == null || claims['type'] != 'temp') throw DemoHttpError(401, 'Invalid token');
        if (q.body['pin'] != DemoAccounts.pin && q.body['pin'] != '${DemoAccounts.pin}78') {
          throw DemoHttpError(401, 'Invalid PIN');
        }
        return (200, _session(_user(claims['sub'] as String)));
      }),
      r('POST', '/auth/set-pin', (q) {
        final claims = decode(q.options.headers['Authorization']?.toString().replaceFirst('Bearer ', ''));
        if (claims == null) throw DemoHttpError(401, 'Unauthorized');
        final user = _user(claims['sub'] as String)..['hasPin'] = true;
        return (200, _session(user));
      }),
      r('PATCH', '/auth/change-pin', (q) {
        q.requireUser();
        if (q.body['oldPin'] != DemoAccounts.pin) throw DemoHttpError(400, 'Invalid current PIN');
        return (200, {'message': 'PIN changed successfully.'});
      }),
      r('POST', '/auth/refresh', (q) {
        final claims = decode(q.body['refreshToken'] as String?);
        if (claims == null) throw DemoHttpError(401, 'Invalid refresh token');
        return (200, {'accessToken': token(claims['sub'], claims['role'])});
      }),
      r('POST', '/auth/signup', (q) {
        final b = q.body;
        if (users.any((u) => u['phone'] == b['phone'])) {
          throw DemoHttpError(409, 'Phone number already exists');
        }
        final user = {
          ...b,
          'id': _id('u'),
          'role': 'USER',
          'membershipStatus': 'PENDING',
          'createdAt': _now(),
        };
        users.add(user);
        return (201, _session(user));
      }),

      // Users ------------------------------------------------------------------
      r('GET', '/users/me', (q) => (200, _user(q.requireUser()))),
      r('PATCH', '/users/me', (q) {
        final user = _user(q.requireUser())..addAll(q.body);
        return (200, user);
      }),
      r('PUT', '/users/me', (q) {
        final user = _user(q.requireUser())..addAll(q.body);
        return (200, user);
      }),
      r('GET', '/users/stats', (q) {
        final live = users.where((u) => u['deletedAt'] == null).toList();
        int count(String role) => live.where((u) => u['role'] == role).length;
        return (
          200,
          {
            'total': live.length,
            'byRole': {'USER': count('USER'), 'ADMIN': count('ADMIN'), 'SUPER_ADMIN': count('SUPER_ADMIN')},
            'recentlyCreated': 5,
            'activeUsers': live.length - 1,
          }
        );
      }),
      r('GET', '/users', (q) {
        final includeDeleted = q.query['includeDeleted'].toString() == 'true';
        final role = q.query['role']?.toString();
        final list = users
            .where((u) => includeDeleted || u['deletedAt'] == null)
            .where((u) => role == null || u['role'] == role)
            .toList();
        return (200, {'data': list, 'meta': {'total': list.length, 'page': 1, 'limit': list.length}});
      }),
      r('GET', '/users/$id', (q) => (200, _user(q.param(0)))),
      r('PATCH', '/users/$id', (q) => (200, _user(q.param(0))..addAll(q.body))),
      r('DELETE', '/users/$id', (q) {
        _user(q.param(0))['deletedAt'] = _now();
        _audit(q.userId, 'DELETE_USER', 'USER', 'ลบผู้ใช้ ${q.param(0)}');
        return (200, {'message': 'User deleted successfully'});
      }),
      r('PATCH', '/users/$id/role', (q) {
        final user = _user(q.param(0))..['role'] = q.body['role'];
        return (200, {'message': 'User role updated successfully', 'user': user});
      }),
      r('PATCH', '/users/$id/restore', (q) {
        _user(q.param(0)).remove('deletedAt');
        return (200, {'message': 'User restored successfully'});
      }),

      // Plots ------------------------------------------------------------------
      r('GET', '/plots/summary', (q) {
        final list = _visiblePlots(q);
        return (
          200,
          {
            'totalArea': list.fold<double>(0, (s, p) => s + (p['areaRai'] as num).toDouble()),
            'totalPlots': list.length,
            'totalYield': 1250,
            'riskyPlots': list.where((p) => p['status'] == 'REJECTED').length,
          }
        );
      }),
      r('GET', '/plots', (q) {
        var list = _visiblePlots(q);
        final status = q.query['status']?.toString();
        if (status != null && status.isNotEmpty) {
          list = list.where((p) => p['status'] == status).toList();
        }
        return (200, {'data': list, 'meta': {'total': list.length, 'page': 1, 'limit': 100}});
      }),
      r('POST', '/plots', (q) {
        final uid = q.requireUser();
        final owner = (q.body['userId'] as String?) ?? uid;
        final plot = {
          ...q.body,
          'id': _id('p'),
          'userId': owner,
          'status': 'PENDING',
          'areaRai': q.body['areaRai'] ?? 2.0,
          'createdAt': _now(),
          'updatedAt': _now(),
          'owner': _owner(owner),
        };
        plots.insert(0, plot);
        return (201, plot);
      }),
      r('GET', '/plots/$id', (q) => (200, _plot(q.param(0)))),
      r('PATCH', '/plots/$id', (q) {
        final plot = _plot(q.param(0))
          ..addAll(q.body)
          ..['updatedAt'] = _now();
        return (200, plot);
      }),
      r('DELETE', '/plots/$id', (q) {
        _plot(q.param(0))['deletedAt'] = _now();
        return (200, {'success': true, 'message': 'Plot deleted successfully (Soft Delete)'});
      }),

      // GAP --------------------------------------------------------------------
      r('GET', '/plots/$id/gap', (q) {
        _plot(q.param(0));
        return (200, gap[q.param(0)]);
      }),
      r('PUT', '/plots/$id/gap', (q) {
        final record = {
          ...?gap[q.param(0)],
          ...q.body,
          'id': gap[q.param(0)]?['id'] ?? _id('g'),
          'plotId': q.param(0),
          'updatedAt': _now(),
        };
        gap[q.param(0)] = record;
        return (200, record);
      }),
      r('GET', '/plots/$id/gap/summary', (q) {
        final done = gap.containsKey(q.param(0));
        return (
          200,
          {
            'total': done ? 1 : 0,
            'statusBreakdown': {'NONE': done ? 0 : 1, 'GREEN': done ? 1 : 0, 'YELLOW': 0, 'RED': 0},
            'overallStatus': done ? 'GREEN' : 'NONE',
          }
        );
      }),
      ..._collection('inputs', () => inputs, r),
      ..._collection('field-activities', () => activities, r),
      ..._collection('harvests', () => harvests, r),
      ..._collection('trainings', () => trainings, r),
      r('GET', '/harvests/$id/post-harvest', (q) {
        for (final list in harvests.values) {
          for (final h in list) {
            if (h['id'] == q.param(0)) return (200, h['postHarvests'] ?? []);
          }
        }
        return (200, <dynamic>[]);
      }),
      r('POST', '/harvests/$id/post-harvest', (q) {
        for (final list in harvests.values) {
          for (final h in list) {
            if (h['id'] == q.param(0)) {
              final item = {...q.body, 'id': _id('ph'), 'createdAt': _now()};
              (h['postHarvests'] ??= <Map<String, dynamic>>[]).add(item);
              return (201, item);
            }
          }
        }
        throw DemoHttpError(404, 'Harvest not found');
      }),

      // Traceability -----------------------------------------------------------
      r('GET', '/traceability/plots/$id', (q) {
        final list = harvests[q.param(0)] ?? const [];
        return (
          200,
          [
            for (final h in list)
              if (h['lotNumber'] != null)
                {
                  'id': 'lot-${h['id']}',
                  'lotNumber': h['lotNumber'],
                  'harvestId': h['id'],
                  'quantity': h['yieldAmount'],
                  'unit': h['yieldUnit'],
                  'status': 'EXPORTED',
                  'createdAt': h['createdAt'],
                },
          ]
        );
      }),
      r('POST', '/traceability/plots/$id/create-lot', (q) {
        final plot = _plot(q.param(0));
        final list = harvests[plot['id']] ?? const [];
        if (list.isEmpty) throw DemoHttpError(400, 'ต้องมีบันทึกการเก็บเกี่ยวก่อนออกเลขล็อต');
        final lot = 'TPT-2568-${(_seq++ % 10000).toString().padLeft(4, '0')}';
        list.last['lotNumber'] = lot;
        return (201, {'lotNumber': lot, 'id': 'lot-$lot'});
      }),
      r('GET', '/traceability/$id', (q) => (200, _traceReport(q.param(0)))),

      // Locations --------------------------------------------------------------
      r('GET', '/locations/regions', (_) => (
            200,
            ['ภาคเหนือ', 'ภาคกลาง', 'ภาคตะวันออกเฉียงเหนือ', 'ภาคตะวันออก', 'ภาคตะวันตก', 'ภาคใต้']
          )),
      r('GET', '/locations/provinces', (q) => (200, {'data': <dynamic>[]})),
      r('GET', '/locations/districts', (q) => (
            200,
            {
              'data': [
                {'id': 1, 'code': '6505', 'nameTh': 'วังทอง', 'provinceCode': q.query['provinceCode'] ?? '65'},
                {'id': 2, 'code': '6501', 'nameTh': 'เมืองพิษณุโลก', 'provinceCode': q.query['provinceCode'] ?? '65'},
                {'id': 3, 'code': '6502', 'nameTh': 'นครไทย', 'provinceCode': q.query['provinceCode'] ?? '65'},
              ],
            }
          )),
      r('GET', '/locations/subdistricts', (q) => (
            200,
            {
              'data': [
                for (final (i, n) in const ['ชัยนาม', 'วังทอง', 'บ้านกลาง', 'แม่ระกา', 'ดินทอง'].indexed)
                  {'id': i + 1, 'code': '65050${i + 1}', 'nameTh': n, 'districtCode': q.query['districtCode']},
              ],
            }
          )),

      // Notifications ----------------------------------------------------------
      r('GET', '/notifications', (q) {
        final uid = q.requireUser();
        final list = notifications.putIfAbsent(uid, () => DemoSeed.notifications(uid));
        return (200, {'data': list, 'total': list.length});
      }),
      r('POST', '/notifications', (q) {
        final target = (q.body['userId'] as String?) ?? q.requireUser();
        _notify(target, q.body['title'] ?? '', q.body['message'] ?? '', q.body['type'] ?? 'INFO',
            q.body['data'] is Map ? Map<String, dynamic>.from(q.body['data']) : null);
        return (201, {'message': 'created'});
      }),
      r('PATCH', '/notifications/$id/read', (q) {
        for (final n in notifications[q.requireUser()] ?? const <Map<String, dynamic>>[]) {
          if (n['id'] == q.param(0)) n['isRead'] = true;
        }
        return (200, {'message': 'ok'});
      }),
      r('DELETE', '/notifications/$id', (q) {
        notifications[q.requireUser()]?.removeWhere((n) => n['id'] == q.param(0));
        return (200, {'message': 'deleted'});
      }),

      // Admin ------------------------------------------------------------------
      r('GET', '/admin/stats', (q) {
        final farmers = _territory(q);
        final list = plots.where((p) => p['deletedAt'] == null).toList();
        return (
          200,
          {
            'totalUsers': farmers.length,
            'totalPlots': list.length,
            'pendingApprovals': list.where((p) => p['status'] == 'PENDING').length,
            'approvedPlots': list.where((p) => p['status'] == 'APPROVED').length,
            'rejectedPlots': list.where((p) => p['status'] == 'REJECTED').length,
          }
        );
      }),
      r('GET', '/admin/plots', (q) {
        final status = q.query['status']?.toString();
        final list = plots
            .where((p) => p['deletedAt'] == null)
            .where((p) => status == null || status.isEmpty || p['status'] == status)
            .toList();
        return (200, {'data': list, 'total': list.length});
      }),
      r('POST', '/admin/plots/$id/approve', (q) {
        final plot = _plot(q.param(0))..['status'] = 'APPROVED';
        _audit(q.userId, 'APPROVE_PLOT', 'PLOT', 'อนุมัติแปลง ${plot['name']}');
        _notify(plot['userId'], 'แปลง${plot['name']}ผ่านการตรวจ', 'เจ้าหน้าที่อนุมัติแปลงแล้ว', 'PLOT_APPROVED');
        return (201, {'message': 'Plot approved successfully', 'plot': plot});
      }),
      r('POST', '/admin/plots/$id/reject', (q) {
        final reason = q.body['reason']?.toString() ?? '';
        final plot = _plot(q.param(0))
          ..['status'] = 'REJECTED'
          ..['rejectReason'] = reason;
        _audit(q.userId, 'REJECT_PLOT', 'PLOT', 'ไม่อนุมัติแปลง ${plot['name']}: $reason');
        _notify(plot['userId'], 'แปลง${plot['name']}ไม่ผ่านการตรวจ', 'โปรดแก้ไขตามคำแนะนำ', 'PLOT_REJECTED', {'reason': reason});
        return (201, {'message': 'Plot rejected successfully'});
      }),
      r('GET', '/admin/users', (q) {
        final status = q.query['status']?.toString();
        final list = _territory(q)
            .where((u) => status == null || u['membershipStatus'] == status)
            .map((u) => {
                  ...u,
                  'plotCount': plots.where((p) => p['userId'] == u['id'] && p['deletedAt'] == null).length,
                })
            .toList();
        final limit = int.tryParse(q.query['limit']?.toString() ?? '') ?? 20;
        return (200, {'data': list.take(limit).toList(), 'total': list.length, 'page': 1, 'limit': limit});
      }),
      r('GET', '/admin/users/$id', (q) => (200, _user(q.param(0)))),
      r('PATCH', '/admin/users/$id', (q) => (200, _user(q.param(0))..addAll(q.body))),
      r('POST', '/admin/users/$id/approve', (q) {
        final user = _user(q.param(0))..['membershipStatus'] = 'APPROVED';
        return (200, {'message': 'User ${user['firstName']} ${user['lastName']} has been approved.'});
      }),
      r('POST', '/admin/users/$id/reject', (q) {
        final user = _user(q.param(0))..['membershipStatus'] = 'REJECTED';
        return (200, {'message': 'User ${user['firstName']} has been rejected.'});
      }),
      r('GET', '/admin', (q) {
        final admins = users
            .where((u) => u['role'] == 'ADMIN' && u['deletedAt'] == null)
            .map((a) => {
                  ...a,
                  'managedUsersCount': users.where((u) => u['adminId'] == a['id']).length,
                })
            .toList();
        return (200, {'data': admins, 'total': admins.length});
      }),
      r('POST', '/admin/create', (q) {
        final admin = {
          ...q.body,
          'id': _id('u-admin'),
          'role': 'ADMIN',
          'hasPin': false,
          'createdAt': _now(),
        }..remove('pin');
        users.add(admin);
        _audit(q.userId, 'CREATE_ADMIN', 'USER', 'เพิ่มเจ้าหน้าที่ ${admin['firstName']} ${admin['lastName']}');
        return (201, {'message': 'Admin created successfully', 'admin': admin});
      }),
      r('DELETE', '/admin/$id', (q) {
        if (q.param(0) == q.userId) throw DemoHttpError(400, 'Cannot delete own account');
        _user(q.param(0))['deletedAt'] = _now();
        return (200, {'message': 'Admin deleted successfully.'});
      }),
      r('PATCH', '/admin/$id/assign-users', (q) {
        final ids = (q.body['userIds'] as List? ?? const []).cast<String>();
        for (final u in users) {
          if (ids.contains(u['id'])) u['adminId'] = q.param(0);
        }
        return (200, {'message': 'Assigned ${ids.length} users.'});
      }),
      r('PATCH', '/admin/reassign/$id', (q) {
        _user(q.param(0))['adminId'] = q.body['newAdminId'];
        return (200, {'message': 'User reassigned.'});
      }),
      r('GET', '/admin/gap-analytics', (q) {
        final list = plots.where((p) => p['deletedAt'] == null).toList();
        final withGap = list.where((p) => gap.containsKey(p['id'])).length;
        return (
          200,
          {
            'totalPlots': list.length,
            'plotsWithGap': withGap,
            'completionRate': list.isEmpty ? 0 : withGap / list.length,
          }
        );
      }),
      r('GET', '/admin/statistics/trends', (q) => (
            200,
            {'data': DemoSeed.trends(q.query['period']?.toString() ?? '7d')}
          )),
      r('GET', '/admin/audit-logs', (q) => (200, {'data': auditLogs, 'total': auditLogs.length})),
      r('POST', '/admin/audit-logs', (q) => (201, {'message': 'logged'})),
      r('POST', '/admin/gap-feedback', (q) => (201, {'message': 'sent'})),
      r('POST', '/admin/profile/photo', (q) => (201, {'url': ''})),

      // Messaging --------------------------------------------------------------
      r('GET', '/admin/messages/conversations', (q) => (200, _conversations(q.requireUser()))),
      r('GET', '/admin/messages/unread-total', (q) {
        final uid = q.requireUser();
        return (200, {'totalUnread': messages.where((m) => m['recipientId'] == uid && m['isRead'] != true).length});
      }),
      r('POST', '/admin/messages/mark-read', (q) {
        final uid = q.requireUser();
        for (final m in messages) {
          if (m['recipientId'] == uid && m['senderId'] == q.body['senderId']) m['isRead'] = true;
        }
        return (200, {'message': 'ok'});
      }),
      r('GET', '/admin/messages', (q) {
        final uid = q.requireUser();
        final sent = q.query['type']?.toString().toUpperCase() == 'SENT';
        final list = messages.where((m) => sent ? m['senderId'] == uid : m['recipientId'] == uid).toList();
        return (200, {'data': list, 'total': list.length});
      }),
      r('POST', '/admin/messages', (q) {
        final uid = q.requireUser();
        final msg = _message(uid, q.body['recipientId'] as String, q.body['subject']?.toString() ?? '', q.body['message']?.toString() ?? '', minutesAgo: 0);
        messages.insert(0, msg);
        return (201, msg);
      }),
      r('POST', '/admin/messages/$id/reply', (q) {
        final uid = q.requireUser();
        final parent = messages.firstWhere((m) => m['id'] == q.param(0), orElse: () => throw DemoHttpError(404, 'Not found'));
        final other = parent['senderId'] == uid ? parent['recipientId'] : parent['senderId'];
        final msg = _message(uid, other as String, 'Re: ${parent['subject']}', q.body['message']?.toString() ?? '', minutesAgo: 0);
        messages.insert(0, msg);
        return (201, msg);
      }),

      // Support ----------------------------------------------------------------
      r('GET', '/support/tickets', (q) {
        final uid = q.requireUser();
        final list = q.isStaff ? tickets : tickets.where((t) => t['userId'] == uid).toList();
        return (200, {'data': list, 'total': list.length});
      }),
      r('POST', '/support/tickets', (q) {
        final uid = q.requireUser();
        final t = {
          ...q.body,
          'id': _id('tk'),
          'userId': uid,
          'user': _owner(uid),
          'status': 'OPEN',
          'replies': <Map<String, dynamic>>[],
          'createdAt': _now(),
          'updatedAt': _now(),
        };
        tickets.insert(0, t);
        return (201, t);
      }),
      r('GET', '/support/tickets/$id', (q) => (
            200,
            tickets.firstWhere((t) => t['id'] == q.param(0), orElse: () => throw DemoHttpError(404, 'Not found'))
          )),
      r('POST', '/support/tickets/$id/reply', (q) {
        final uid = q.requireUser();
        final t = tickets.firstWhere((t) => t['id'] == q.param(0), orElse: () => throw DemoHttpError(404, 'Not found'));
        (t['replies'] as List).add({
          'id': _id('rp'),
          'message': q.body['message'],
          'userId': uid,
          'user': _owner(uid),
          'createdAt': _now(),
        });
        if (q.isStaff) t['status'] = 'IN_PROGRESS';
        return (201, t);
      }),
      r('PATCH', '/support/tickets/$id/status', (q) {
        final t = tickets.firstWhere((t) => t['id'] == q.param(0), orElse: () => throw DemoHttpError(404, 'Not found'));
        t['status'] = q.body['status'] ?? t['status'];
        t['updatedAt'] = _now();
        return (200, t);
      }),
      r('PATCH', '/support/tickets/$id/close', (q) {
        final t = tickets.firstWhere((t) => t['id'] == q.param(0), orElse: () => throw DemoHttpError(404, 'Not found'));
        t['status'] = 'CLOSED';
        t['updatedAt'] = _now();
        return (200, t);
      }),

      // Feedback, uploads, reports, health -------------------------------------
      r('POST', '/feedback/rate-app', (q) => (201, {'message': 'thanks'})),
      r('GET', '/feedback/my-rating', (q) => (200, null)),
      r('GET', '/feedback/stats', (q) => (200, {'average': 4.6, 'count': 128})),
      r('POST', '/upload', (q) => (201, {'url': '', 'filename': 'demo.jpg'})),
      r('GET', '/health', (_) => (200, {'status': 'ok', 'mode': 'demo'})),
    ];
  }

  List<(String, RegExp, _Handler)> _collection(
    String name,
    Map<String, List<Map<String, dynamic>>> Function() store,
    (String, RegExp, _Handler) Function(String, String, _Handler) r,
  ) {
    const id = r'([^/]+)';
    return [
      r('GET', '/plots/$id/$name', (q) => (200, {'data': store()[q.param(0)] ?? const []})),
      r('GET', '/plots/$id/$name/$id', (q) => (
            200,
            (store()[q.param(0)] ?? const []).firstWhere(
              (e) => e['id'] == q.param(1),
              orElse: () => throw DemoHttpError(404, 'Not found'),
            )
          )),
      r('POST', '/plots/$id/$name', (q) {
        final item = {...q.body, 'id': _id(name), 'plotId': q.param(0), 'createdAt': _now(), 'updatedAt': _now()};
        store().putIfAbsent(q.param(0), () => []).insert(0, item);
        return (201, item);
      }),
      r('PUT', '/plots/$id/$name/$id', (q) {
        final list = store()[q.param(0)] ?? const [];
        final item = list.firstWhere((e) => e['id'] == q.param(1), orElse: () => throw DemoHttpError(404, 'Not found'));
        item
          ..addAll(q.body)
          ..['updatedAt'] = _now();
        return (200, item);
      }),
      r('DELETE', '/plots/$id/$name/$id', (q) {
        store()[q.param(0)]?.removeWhere((e) => e['id'] == q.param(1));
        return (200, {'message': 'deleted'});
      }),
    ];
  }

  Map<String, dynamic> _traceReport(String lotNumber) {
    for (final entry in harvests.entries) {
      for (final h in entry.value) {
        if (h['lotNumber'] != lotNumber) continue;
        final plot = _plot(entry.key);
        final owner = _user(plot['userId'] as String);
        return {
          'lotNumber': lotNumber,
          'status': 'EXPORTED',
          'createdAt': h['createdAt'],
          'product': {'name': 'ใบกระท่อมตากแห้ง', 'quantity': h['yieldAmount'], 'unit': h['yieldUnit'], 'grade': h['qualityGrade']},
          'farmer': {'firstName': owner['firstName'], 'lastName': owner['lastName'], 'province': owner['province']},
          'plot': {
            'id': plot['id'],
            'name': plot['name'],
            'areaRai': plot['areaRai'],
            'species': plot['species'],
            'province': plot['province'],
            'district': plot['district'],
            'subDistrict': plot['subDistrict'],
            'status': plot['status'],
            'geometry': plot['geometry'],
          },
          'gap': {
            ...?gap[entry.key],
            'certified': plot['status'] == 'APPROVED',
          },
          'inputs': inputs[entry.key] ?? const [],
          'activities': activities[entry.key] ?? const [],
          'harvest': h,
          'postHarvests': h['postHarvests'] ?? const [],
          'trainings': trainings[entry.key] ?? const [],
        };
      }
    }
    throw DemoHttpError(404, 'Lot not found');
  }

  Map<String, dynamic> _message(String from, String to, String subject, String body, {required int minutesAgo}) {
    final sender = _user(from);
    final recipient = _user(to);
    return {
      'id': _id('m'),
      'senderId': from,
      'recipientId': to,
      'sender': {'id': from, 'firstName': sender['firstName'], 'lastName': sender['lastName'], 'role': sender['role']},
      'recipient': {'id': to, 'firstName': recipient['firstName'], 'lastName': recipient['lastName'], 'role': recipient['role']},
      'subject': subject,
      'message': body,
      'content': body,
      'isRead': minutesAgo > 60,
      'createdAt': DateTime.now().subtract(Duration(minutes: minutesAgo)).toUtc().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _seedMessages() => [
        _message(DemoSeed.superId, DemoSeed.adminId, 'สรุปผลการตรวจแปลงประจำเดือน',
            'รบกวนส่งสรุปจำนวนแปลงที่ตรวจแล้วในอำเภอวังทองภายในวันศุกร์ครับ', minutesAgo: 35),
        _message(DemoSeed.adminId, DemoSeed.superId, 'คำขอเพิ่มสิทธิ์พื้นที่',
            'ขอเพิ่มพื้นที่ดูแลตำบลดินทองเนื่องจากมีเกษตรกรสมัครเพิ่ม', minutesAgo: 60 * 26),
        _message('u-admin-02', DemoSeed.adminId, 'แลกเปลี่ยนแนวทางตรวจหมวด 1.5',
            'ทางทุ่งสงใช้แบบฟอร์มตรวจการตากแห้งแบบใหม่ ส่งให้ดูประกอบครับ', minutesAgo: 60 * 50),
      ];

  List<Map<String, dynamic>> _conversations(String uid) {
    final byPartner = <String, Map<String, dynamic>>{};
    for (final m in messages) {
      final partner = m['senderId'] == uid ? m['recipientId'] : (m['recipientId'] == uid ? m['senderId'] : null);
      if (partner == null) continue;
      final p = _user(partner as String);
      final existing = byPartner[partner];
      final unread = (existing?['unreadCount'] as int? ?? 0) + (m['recipientId'] == uid && m['isRead'] != true ? 1 : 0);
      byPartner[partner] = {
        'partner': {'id': partner, 'firstName': p['firstName'], 'lastName': p['lastName'], 'role': p['role']},
        'id': partner,
        'firstName': p['firstName'],
        'lastName': p['lastName'],
        'role': p['role'],
        'lastMessage': existing?['lastMessage'] ?? m,
        'unreadCount': unread,
      };
    }
    return byPartner.values.toList();
  }

  List<Map<String, dynamic>> _seedTickets() => [
        {
          'id': 'tk-1',
          'userId': DemoSeed.farmerId,
          'user': {'id': DemoSeed.farmerId, 'firstName': 'สมชาย', 'lastName': 'ใจดี'},
          'subject': 'วาดขอบเขตแปลงไม่ได้ในบางพื้นที่',
          'description': 'เมื่อซูมแผนที่มาก ๆ ภาพดาวเทียมไม่ชัด อยากทราบวิธีวาดให้ตรงแนวรั้ว',
          'category': 'MAP',
          'status': 'IN_PROGRESS',
          'replies': [
            {
              'id': 'rp-1',
              'message': 'แนะนำให้เดินรอบแปลงแล้วใช้ปุ่มปักหมุดตามตำแหน่ง GPS ทีละจุดครับ',
              'userId': DemoSeed.adminId,
              'user': {'id': DemoSeed.adminId, 'firstName': 'ประเสริฐ', 'lastName': 'วงศ์ไทย', 'role': 'ADMIN'},
              'createdAt': DemoSeed.iso(DateTime.now().subtract(const Duration(hours: 20))),
            },
          ],
          'createdAt': DemoSeed.iso(DateTime.now().subtract(const Duration(days: 2))),
          'updatedAt': DemoSeed.iso(DateTime.now().subtract(const Duration(hours: 20))),
        },
        {
          'id': 'tk-2',
          'userId': 'u-farmer-04',
          'user': {'id': 'u-farmer-04', 'firstName': 'สุนทร', 'lastName': 'พรหมมา'},
          'subject': 'สอบถามสถานะการสมัครสมาชิก',
          'description': 'สมัครไว้สองวันแล้ว ยังไม่ได้รับการอนุมัติ',
          'category': 'ACCOUNT',
          'status': 'OPEN',
          'replies': <Map<String, dynamic>>[],
          'createdAt': DemoSeed.iso(DateTime.now().subtract(const Duration(hours: 6))),
          'updatedAt': DemoSeed.iso(DateTime.now().subtract(const Duration(hours: 6))),
        },
      ];
}
