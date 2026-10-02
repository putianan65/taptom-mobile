import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/support_service.dart';
import '../../../../core/widgets/nature_background.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/user_model.dart'; // For UserRole
import '../../../../core/services/auth_service.dart';
import '../../auth/auth_provider.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  bool _isLoading = false;
  List<Ticket> _tickets = [];
  String _filterStatus = 'ALL';

  // Helper service
  // Note: Ideally provided by Provider<SupportService> in app.dart but checking there
  // If not in app.dart, instance local or assume provided.
  // Plan implies Service creation, likely provided or instantiable.
  final SupportService _supportService = SupportService();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final userId = (user?.role == UserRole.admin || user?.role == UserRole.superAdmin) 
          ? null // Admin sees all
          : user?.id; // User sees own

      final tickets = await _supportService.getTickets(
        status: _filterStatus,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('รายการแจ้งปัญหา', style: const TextStyle()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.funnelSimple, color: Colors.white),
              onPressed: _showFilterDialog,
            )
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tickets.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _tickets.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildTicketCard(_tickets[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
             // Create Ticket logic (Not explicitly in plan but expected)
             // For now assume just listing/viewing per plan scope "List/Filter tickets"
          },
          backgroundColor: AppColors.primary,
          label: Text('แจ้งปัญหา', style: TextStyle(color: Colors.white)),
          icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsRegular.ticket, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'ไม่พบรายการแจ้งปัญหา',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    Color statusColor = Colors.grey;
    String statusText = ticket.status;
    switch (ticket.status) {
      case 'OPEN':
        statusColor = Colors.blue;
        statusText = 'รอรับเรื่อง';
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange;
        statusText = 'กำลังดำเนินการ';
        break;
      case 'RESOLVED':
        statusColor = Colors.green;
        statusText = 'แก้ไขแล้ว';
        break;
      case 'CLOSED':
        statusColor = Colors.grey;
        statusText = 'ปิดงาน';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => context.push('/support-tickets/${ticket.id}', extra: ticket),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ticket.subject,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            ticket.message,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[100],
          child: const Icon(PhosphorIconsRegular.ticket, color: AppColors.primary),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('กรองสถานะ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map((status) {
            return ListTile(
              title: Text(status),
              leading: Radio<String>(
                value: status,
                groupValue: _filterStatus,
                onChanged: (val) {
                  setState(() => _filterStatus = val!);
                  Navigator.pop(context);
                  _loadTickets();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
