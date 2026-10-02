import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../super_admin/screens/admin_management_screen.dart' show officerName, officerScope;
import '../providers/message_provider.dart';

/// New message between staff. Officers write to the system administrators;
/// administrators can write to any officer.
class AdminMessageComposeScreen extends StatefulWidget {
  const AdminMessageComposeScreen({super.key, this.initialRecipientId});

  final String? initialRecipientId;

  @override
  State<AdminMessageComposeScreen> createState() => _AdminMessageComposeScreenState();
}

class _AdminMessageComposeScreenState extends State<AdminMessageComposeScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _recipients = [];
  late String? _recipientId = widget.initialRecipientId;
  XFile? _image;
  bool _loading = true;
  bool _sending = false;

  bool get _superAdmin => context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    final superAdmin = _superAdmin;
    try {
      final raw = superAdmin
          ? await context.read<SuperAdminService>().getAdminList()
          : await context.read<AdminService>().getSuperAdmins();
      final list = [for (final r in raw) if (r is Map) Map<String, dynamic>.from(r)];
      if (!mounted) return;
      setState(() {
        _recipients = list;
        if (!list.any((r) => '${r['id']}' == _recipientId)) _recipientId = null;
        if (_recipientId == null && list.length == 1) _recipientId = '${list.first['id']}';
        _loading = false;
      });
    } on Object catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (_recipientId == null) return AppToast.error(context, 'เลือกผู้รับก่อนส่ง');
    if (subject.isEmpty || body.isEmpty) return AppToast.error(context, 'กรอกหัวข้อและข้อความให้ครบ');

    setState(() => _sending = true);
    try {
      var text = body;
      if (_image != null) {
        final file = File(_image!.path);
        final url = _superAdmin
            ? await context.read<SuperAdminService>().uploadFile(file)
            : await context.read<AdminService>().uploadFile(file);
        text += '\n\n![รูปภาพ]($url)';
      }
      if (!mounted) return;
      await context.read<MessageProvider>().sendMessage(recipientId: _recipientId!, subject: subject, message: text);
      if (!mounted) return;
      AppToast.success(context, 'ส่งข้อความแล้ว');
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PageScaffold(
      title: 'ข้อความใหม่',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
          child: AppButton(
            label: 'ส่งข้อความ',
            icon: AppIcons.send,
            expand: true,
            loading: _sending,
            onPressed: _send,
          ),
        ),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            maxWidth: Breakpoints.maxForm,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(_superAdmin ? 'ถึงเจ้าหน้าที่' : 'ถึงผู้ดูแลระบบ'),
                if (_loading)
                  const SkeletonBox(height: 56, radius: Radii.md)
                else if (_recipients.isEmpty)
                  const InlineBanner(tone: Tone.warning, title: 'ไม่พบผู้รับ', message: 'ยังไม่มีบัญชีที่ส่งข้อความถึงได้')
                else
                  DropdownButtonFormField<String>(
                    value: _recipientId,
                    isExpanded: true,
                    hint: const Text('เลือกผู้รับ'),
                    items: [
                      for (final r in _recipients)
                        DropdownMenuItem(
                          value: '${r['id']}',
                          child: Text(
                            _superAdmin ? '${officerName(r)} · ${officerScope(r)}' : officerName(r),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _recipientId = v),
                  ),
                const SizedBox(height: Space.lg),
                AppTextField(label: 'หัวข้อ', controller: _subject, hint: 'เช่น ขออนุมัติย้ายสมาชิก'),
                const SizedBox(height: Space.lg),
                AppTextField(
                  label: 'ข้อความ',
                  controller: _body,
                  maxLines: 8,
                  minLines: 5,
                  hint: 'รายละเอียดที่ต้องการแจ้ง',
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: Space.lg),
                  if (_image == null)
                    AppButton.ghost(label: 'แนบรูปภาพ', icon: AppIcons.image, onPressed: _pickImage)
                  else
                    AppCard(
                      padding: const EdgeInsets.all(Space.sm),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.sm),
                            child: Image.file(File(_image!.path), width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(child: Text('แนบรูปภาพ 1 รูป', style: context.text.bodyMedium)),
                          IconButton(
                            tooltip: 'นำออก',
                            onPressed: () => setState(() => _image = null),
                            icon: Icon(AppIcons.close, color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
