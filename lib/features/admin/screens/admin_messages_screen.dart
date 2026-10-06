import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/conversation_model.dart';
import '../providers/message_provider.dart';

/// Staff inbox: one row per conversation partner, newest first.
class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MessageProvider>().loadConversations();
    });
  }

  Future<void> _compose() async {
    final sent = await context.push<bool>(Routes.adminMessageNew);
    if (sent == true && mounted) context.read<MessageProvider>().loadConversations();
  }

  Future<void> _open(Conversation c) async {
    await context.push(Routes.adminMessage(c.partner.id), extra: c.partner);
    if (mounted) context.read<MessageProvider>().loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final list = provider.conversationList;

    return PageScaffold(
      title: 'ข้อความ',
      subtitle: provider.totalUnreadCount > 0 ? 'ยังไม่ได้อ่าน ${provider.totalUnreadCount} ข้อความ' : 'ติดต่อระหว่างเจ้าหน้าที่',
      onRefresh: provider.loadConversations,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(AppIcons.edit),
        label: const Text('เขียนข้อความ'),
      ),
      slivers: [
        if (provider.isLoading && list.isEmpty)
          const SliverToBoxAdapter(child: SkeletonList(count: 5))
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีข้อความ',
                message: 'เริ่มบทสนทนากับเจ้าหน้าที่หรือผู้ดูแลระบบได้จากปุ่มเขียนข้อความ',
                actionLabel: 'เขียนข้อความ',
                onAction: _compose,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: ListGroup(
              children: [
                for (final c in list) _ConversationRow(conversation: c, onTap: () => _open(c)),
              ],
            ).entrance(context),
          ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = conversation;
    final unread = c.unreadCount > 0;
    final last = c.lastMessage;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
        child: Row(
          children: [
            InitialsAvatar(name: c.partner.fullName, photoUrl: c.partner.photoUrl),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.partner.fullName,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(StatusLabels.role(c.partner.role), style: context.text.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    last?.preview ?? 'เริ่มบทสนทนา',
                    style: context.text.bodySmall?.copyWith(color: unread ? p.ink : p.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (last != null) Text(ThaiDate.relative(last.createdAt), style: context.text.labelSmall),
                const SizedBox(height: 4),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: p.brand, borderRadius: Radii.chip),
                    child: Text(
                      '${c.unreadCount}',
                      style: context.text.labelSmall?.tabular.copyWith(color: p.onBrand),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
