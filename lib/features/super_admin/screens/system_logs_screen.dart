import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../data/models/audit_log_model.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _logs = [];
    });

    try {
      final service = context.read<SuperAdminService>();
      final rawLogs = await service.getAuditLogs(page: 1);
      final logs = rawLogs.map((e) => AuditLog.fromJson(e)).toList();
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
          _hasMore = logs.length >= 20; // Assume limit is 20
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = context.read<SuperAdminService>();
      final nextPage = _currentPage + 1;
      final rawLogs = await service.getAuditLogs(page: nextPage);
      final newLogs = rawLogs.map((e) => AuditLog.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _logs.addAll(newLogs);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _hasMore = newLogs.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'บันทึกการใช้งาน (Audit Logs)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.superAdminDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.clipboardText,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่พบรายการบันทึก',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _logs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final log = _logs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                            color: AppColors.superAdminPrimary.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.superAdminPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.clipboardText,
                            color: AppColors.superAdminPrimary,
                            size: 24),
                        ),
                        title: Text(
                          log.action,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              log.details,
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                             Row(
                               children: [
                                 Icon(PhosphorIconsRegular.user, size: 14, color: Colors.grey[600]),
                                 const SizedBox(width: 4),
                                 Text(
                                    log.userId ?? "System",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                 ),
                                 const SizedBox(width: 12),
                                 Icon(PhosphorIconsRegular.clock, size: 14, color: Colors.grey[600]),
                                 const SizedBox(width: 4),
                                 Text(
                                    log.timestamp,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                 ),
                               ],
                             )
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
    );
  }
}
