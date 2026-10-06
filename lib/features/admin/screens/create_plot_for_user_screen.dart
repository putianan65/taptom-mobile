import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../map/screens/map_drawing_screen.dart';

/// Step one of registering a plot on a member's behalf: pick the member,
/// then draw the boundary on the map.
class CreatePlotForUserScreen extends StatefulWidget {
  const CreatePlotForUserScreen({super.key, this.initialUser});

  final UserModel? initialUser;

  @override
  State<CreatePlotForUserScreen> createState() => _CreatePlotForUserScreenState();
}

class _CreatePlotForUserScreenState extends State<CreatePlotForUserScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<AdminService>().getUsers(status: 'APPROVED');
      if (!mounted) return;
      setState(() {
        _users = users.where((u) => u.role == UserRole.farmer).toList();
        _loading = false;
      });
      final initial = widget.initialUser;
      if (initial != null && _users.any((u) => u.id == initial.id)) _draw(initial);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _draw(UserModel user) async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapDrawingScreen(isAdmin: true, targetUserId: user.id)),
    );
    if (created != null && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final users = q.isEmpty
        ? _users
        : _users
            .where((u) => '${u.fullName} ${u.phone} ${u.district ?? ''} ${u.subdistrict ?? ''}'.toLowerCase().contains(q))
            .toList();

    return PageScaffold(
      title: 'เพิ่มแปลงให้สมาชิก',
      subtitle: 'เลือกเจ้าของแปลง แล้ววาดขอบเขตบนแผนที่',
      onRefresh: _load,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: AppSearchField(
              hint: 'ชื่อ เบอร์โทร หรือพื้นที่',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 5))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (users.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: q.isEmpty ? 'ยังไม่มีสมาชิกที่อนุมัติแล้ว' : 'ไม่พบสมาชิกที่ค้นหา',
                message: q.isEmpty ? 'อนุมัติใบสมัครก่อน จึงจะเพิ่มแปลงให้สมาชิกได้' : null,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: ListGroup(
              children: [
                for (final u in users)
                  ListRow(
                    leading: InitialsAvatar(name: u.fullName, photoUrl: u.photoUrl, size: 40),
                    title: u.fullName,
                    subtitle: [
                      u.phone,
                      if ((u.subdistrict ?? '').isNotEmpty) 'ต.${u.subdistrict}',
                      if ((u.district ?? '').isNotEmpty) 'อ.${u.district}',
                    ].join(' · '),
                    trailing: const Icon(AppIcons.pinLine, size: 20),
                    showChevron: false,
                    onTap: () => _draw(u),
                  ),
              ],
            ).entrance(context),
          ),
      ],
    );
  }
}
