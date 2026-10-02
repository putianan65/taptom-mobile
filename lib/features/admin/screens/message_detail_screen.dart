import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../providers/message_provider.dart';

/// One conversation between two staff members.
class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({super.key, required this.id, this.message, this.partner});

  /// The partner's user id.
  final String id;
  final Message? message;
  final UserModel? partner;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessageProvider>();
      await provider.loadMessages();
      provider.markThreadAsRead(widget.id);
      _toBottom(jump: true);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      jump ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: Motion.base, curve: Motion.standard);
    });
  }

  Future<void> _send(List<Message> thread) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final provider = context.read<MessageProvider>();
    try {
      if (thread.isNotEmpty) {
        await provider.replyMessage(messageId: thread.last.id, message: text);
      } else {
        await provider.sendMessage(recipientId: widget.id, message: text);
      }
      _input.clear();
      _toBottom();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final provider = context.watch<MessageProvider>();
    final me = context.watch<AuthProvider>().currentUser;
    final thread = provider.getThread(widget.id);
    final partner = widget.partner ??
        (widget.message != null ? provider.getPartner(widget.message!) : null) ??
        (thread.isNotEmpty ? provider.getPartner(thread.first) : null);
    final name = partner?.fullName ?? 'บทสนทนา';

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        shape: Border(bottom: BorderSide(color: p.line)),
        title: Row(
          children: [
            InitialsAvatar(name: name, photoUrl: partner?.photoUrl, size: 36),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                  if (partner != null) Text(StatusLabels.role(partner.role), style: context.text.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoading && thread.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : thread.isEmpty
                    ? const EmptyState(
                        title: 'เริ่มบทสนทนา',
                        message: 'พิมพ์ข้อความด้านล่างเพื่อส่งถึงผู้รับ',
                        mood: MascotMood.wave,
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.md),
                        itemCount: thread.length,
                        itemBuilder: (context, i) {
                          final m = thread[i];
                          final prev = i > 0 ? thread[i - 1] : null;
                          final newDay = prev == null ||
                              prev.createdAt.day != m.createdAt.day ||
                              prev.createdAt.month != m.createdAt.month;
                          return Column(
                            children: [
                              if (newDay)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: Space.md),
                                  child: Text(ThaiDate.long(m.createdAt), style: context.text.labelSmall),
                                ),
                              _Bubble(message: m, mine: m.sender.id == me?.id),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.line)),
            ),
            padding: EdgeInsets.fromLTRB(
              Space.md,
              Space.sm,
              Space.sm,
              Space.sm + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ'),
                  ),
                ),
                const SizedBox(width: Space.sm),
                AppIconButton(
                  icon: AppIcons.send,
                  tooltip: 'ส่ง',
                  background: p.brand,
                  foreground: p.onBrand,
                  onPressed: _sending ? null : () => _send(thread),
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
  const _Bubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    final showSubject = message.subject.isNotEmpty && message.subject != 'ข้อความสนทนา';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: Space.sm),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? p.brand : p.surface,
            border: mine ? null : Border.all(color: p.line),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 6),
              bottomRight: Radius.circular(mine ? 6 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSubject)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.subject,
                    style: context.text.labelLarge?.copyWith(color: mine ? p.onBrand : p.ink),
                  ),
                ),
              for (final url in message.images)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  ),
                ),
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: context.text.bodyMedium?.copyWith(color: mine ? p.onBrand : p.ink),
                ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: context.text.labelSmall?.tabular.copyWith(
                    color: mine ? p.onBrand.withValues(alpha: 0.7) : p.inkSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
