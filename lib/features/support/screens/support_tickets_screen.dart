import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/services/support_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/ticket_model.dart';
import '../../auth/auth_provider.dart';

/// Help requests. Members see and open their own; staff see the queue.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final _service = SupportService();
  List<Ticket>? _tickets;
  String? _error;
  bool _openOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await _service.getTickets();
      list.sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
      if (mounted) setState(() => _tickets = list);
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'โหลดรายการไม่สำเร็จ');
    }
  }

  Future<void> _create() async {
    final data = await showAppSheet<Map<String, String>>(
      context,
      title: 'แจ้งปัญหาหรือขอความช่วยเหลือ',
      child: const _NewTicketForm(),
    );
    if (data == null || !mounted) return;
    try {
      final t = await _service.createTicket(
        subject: data['subject']!,
        message: data['message']!,
        category: data['category']!,
        priority: data['priority']!,
      );
      if (!mounted) return;
      AppToast.success(context, 'ส่งเรื่องแล้ว เจ้าหน้าที่จะตอบกลับในเรื่องนี้');
      await _load();
      if (mounted) _open(t);
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'ส่งเรื่องไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  Future<void> _open(Ticket t) async {
    await context.push(Routes.supportTicket(t.id), extra: t);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AuthProvider>().currentUser?.isStaff ?? false;
    final all = _tickets;
    bool isOpen(Ticket t) => t.status != 'CLOSED' && t.status != 'RESOLVED';
    final tickets = all == null ? null : (_openOnly ? all.where(isOpen).toList() : all);

    return PageScaffold(
      title: staff ? 'คำร้องจากผู้ใช้' : 'แจ้งปัญหา',
      subtitle: staff ? 'ตอบกลับและติดตามสถานะ' : 'ติดตามเรื่องที่แจ้งไว้',
      onRefresh: _load,
      floatingActionButton: staff
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(AppIcons.add),
              label: const Text('แจ้งเรื่องใหม่'),
            ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: FilterChips<bool>(
              value: _openOnly,
              onChanged: (v) => setState(() => _openOnly = v),
              options: [
                (true, 'กำลังดำเนินการ', all?.where(isOpen).length),
                (false, 'ทั้งหมด', all?.length),
              ],
            ),
          ),
        ),
        if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (tickets == null)
          const SliverToBoxAdapter(child: SkeletonList(count: 4, thumbnail: false))
        else if (tickets.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: _openOnly ? 'ไม่มีเรื่องค้างอยู่' : 'ยังไม่มีคำร้อง',
                message: staff ? null : 'มีปัญหาการใช้งานหรือข้อสงสัยเรื่องการตรวจ แจ้งได้จากปุ่มด้านล่าง',
                mood: _openOnly ? MascotMood.joy : MascotMood.think,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final t = tickets[i];
              final (label, tone) = StatusLabels.ticket(t.status);
              return AppCard(
                onTap: () => _open(t),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(t.subject, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        StatusBadge(label: label, tone: tone),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(t.message, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.sm),
                    Text(
                      [
                        if (staff) t.user.fullName,
                        ThaiDate.relative(t.updatedAt ?? t.createdAt),
                        if (t.replies.isNotEmpty) '${t.replies.length} การตอบกลับ',
                      ].join(' · '),
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ).entrance(context, index: i);
            },
          ),
      ],
    );
  }
}

class _NewTicketForm extends StatefulWidget {
  const _NewTicketForm();

  @override
  State<_NewTicketForm> createState() => _NewTicketFormState();
}

class _NewTicketFormState extends State<_NewTicketForm> {
  // The API's TicketCategory values.
  static const _categories = [
    ('QUESTION', 'สอบถามการใช้งาน'),
    ('BUG', 'แอปทำงานผิดพลาด'),
    ('FEATURE', 'อยากให้เพิ่ม'),
    ('OTHER', 'เรื่องอื่น'),
  ];

  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'QUESTION';
  bool _urgent = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('เรื่อง'),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final (code, label) in _categories)
                  ChoiceChip(
                    label: Text(label),
                    selected: _category == code,
                    onSelected: (_) => setState(() => _category = code),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            AppTextField(
              label: 'หัวข้อ',
              controller: _subject,
              hint: 'เช่น แก้ไขขอบเขตแปลงไม่ได้',
              maxLength: 80,
              validator: (v) => (v ?? '').trim().isEmpty ? 'ใส่หัวข้อสั้น ๆ' : null,
            ),
            const SizedBox(height: Space.lg),
            AppTextField(
              label: 'รายละเอียด',
              controller: _message,
              hint: 'เล่าสิ่งที่เกิดขึ้น และสิ่งที่ต้องการให้ช่วย',
              maxLines: 6,
              minLines: 4,
              maxLength: 1000,
              validator: (v) => (v ?? '').trim().length < 10 ? 'อธิบายเพิ่มอีกนิด' : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _urgent,
              onChanged: (v) => setState(() => _urgent = v),
              title: Text('เรื่องเร่งด่วน', style: context.text.titleSmall),
              subtitle: Text('เช่น กระทบการตรวจที่ใกล้ถึงกำหนด', style: context.text.bodySmall),
            ),
            const SizedBox(height: Space.md),
            AppButton(
              label: 'ส่งเรื่อง',
              icon: AppIcons.send,
              expand: true,
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.of(context).pop({
                  'subject': _subject.text.trim(),
                  'message': _message.text.trim(),
                  'category': _category,
                  'priority': _urgent ? 'HIGH' : 'MEDIUM',
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
