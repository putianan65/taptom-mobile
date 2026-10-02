import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/support_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/ticket_model.dart';
import '../../auth/auth_provider.dart';

/// One help request as a conversation. Staff can also move it through
/// its statuses.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.id, this.ticket});

  final String id;
  final Ticket? ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _service = SupportService();
  final _reply = TextEditingController();
  late Ticket? _ticket = widget.ticket;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _service.getTicket(widget.id);
      if (mounted) setState(() => _ticket = t);
    } on Object catch (_) {
      if (mounted && _ticket == null) setState(() => _error = 'โหลดคำร้องไม่สำเร็จ');
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.replyToTicket(ticketId: widget.id, message: text);
      _reply.clear();
      await _load();
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'ส่งข้อความไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await _service.updateTicketStatus(widget.id, status);
      await _load();
      if (mounted) AppToast.success(context, 'เปลี่ยนสถานะเป็น${StatusLabels.ticket(status).$1}แล้ว');
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'เปลี่ยนสถานะไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = context.watch<AuthProvider>().currentUser;
    final staff = me?.isStaff ?? false;
    final t = _ticket;

    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error == null
            ? const Center(child: CircularProgressIndicator())
            : ErrorState(message: _error, onRetry: _load),
      );
    }

    final (label, tone) = StatusLabels.ticket(t.status);
    final closed = t.status == 'CLOSED';

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: p.line)),
        title: Text(t.subject, style: context.text.titleMedium, overflow: TextOverflow.ellipsis),
        actions: [
          if (staff)
            PopupMenuButton<String>(
              tooltip: 'เปลี่ยนสถานะ',
              icon: const Icon(AppIcons.sliders),
              onSelected: _setStatus,
              itemBuilder: (_) => [
                for (final s in const ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'])
                  PopupMenuItem(value: s, enabled: s != t.status, child: Text(StatusLabels.ticket(s).$1)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(Space.lg),
                children: [
                  Row(
                    children: [
                      StatusBadge(label: label, tone: tone),
                      if (t.priority == 'HIGH') ...[
                        const SizedBox(width: Space.sm),
                        const StatusBadge(label: 'เร่งด่วน', tone: Tone.danger, dot: false),
                      ],
                      const Spacer(),
                      Text(ThaiDate.withTime(t.createdAt), style: context.text.labelSmall),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  _Bubble(
                    author: t.user.fullName.isEmpty ? 'ผู้แจ้ง' : t.user.fullName,
                    text: t.message,
                    time: t.createdAt,
                    mine: t.user.id == me?.id,
                  ),
                  for (final r in t.replies)
                    _Bubble(
                      author: r.author.fullName.isEmpty ? 'เจ้าหน้าที่' : r.author.fullName,
                      text: r.message,
                      time: r.createdAt,
                      mine: r.author.id == me?.id,
                      staff: r.author.isStaff,
                    ),
                ],
              ),
            ),
          ),
          if (closed)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md + MediaQuery.paddingOf(context).bottom),
              color: p.surfaceSunken,
              child: Text('คำร้องนี้ปิดแล้ว หากยังมีปัญหา แจ้งเรื่องใหม่ได้', style: context.text.bodySmall, textAlign: TextAlign.center),
            )
          else
            Container(
              decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
              padding: EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm + MediaQuery.paddingOf(context).bottom),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ'),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  AppIconButton(
                    icon: AppIcons.send,
                    tooltip: 'ส่ง',
                    background: p.brand,
                    foreground: p.onBrand,
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.author, required this.text, required this.time, required this.mine, this.staff = false});

  final String author;
  final String text;
  final DateTime time;
  final bool mine;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  staff && !mine ? '$author · เจ้าหน้าที่' : author,
                  style: context.text.labelSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: mine ? p.brand : p.surface,
                  border: mine ? null : Border.all(color: p.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(text, style: context.text.bodyMedium?.copyWith(color: mine ? p.onBrand : p.ink)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(ThaiDate.relative(time), style: context.text.labelSmall?.copyWith(color: p.inkSubtle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
