import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/super_admin_service.dart';
import '../../../core/utils/admin_error_handler.dart';
import 'dart:ui';

/// Admin Detail Screen - Shows admin info, managed users, and assignment actions
class AdminDetailScreen extends StatefulWidget {
  final Map<String, dynamic> admin;

  const AdminDetailScreen({super.key, required this.admin});

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  List<dynamic> _allUsers = [];
  List<dynamic> _managedUsers = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  String get _adminId => widget.admin['id'] ?? '';
  String get _adminName =>
      '${widget.admin['firstName'] ?? ''} ${widget.admin['lastName'] ?? ''}'.trim();
  String get _adminPhone => widget.admin['phone'] ?? '';
  int get _managedUsersCount => widget.admin['managedUsersCount'] ?? 0;
  String? get _province => widget.admin['province'];
  String? get _district => widget.admin['district'];
  String? get _region => widget.admin['region'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<SuperAdminService>();
      final admins = await service.getAdminList();
      final thisAdmin = admins.firstWhere(
        (a) => a['id'] == _adminId,
        orElse: () => widget.admin,
      );

      List<dynamic> managed = thisAdmin['managedUsers'] is List ? thisAdmin['managedUsers'] : [];

      // Also pre-load all users for assignment dialog
      try {
        _allUsers = await service.getUsers();
        
        // Fallback: If managedUsers from getAdminList is empty or to be absolutely sure,
        // filter from _allUsers where managedByAdminId == this admin's id
        final filteredManaged = _allUsers.where((u) {
          if (u is! Map) return false;
          final mid = u['managedByAdminId']?.toString() ?? u['adminId']?.toString();
          return mid == _adminId;
        }).toList();

        // Use the filtered list if it found more users, else stick to what getAdminList gave
        if (filteredManaged.isNotEmpty || managed.isEmpty) {
            managed = filteredManaged;
        }

      } catch (_) {
        _allUsers = [];
      }

      if (mounted) {
        setState(() {
          _managedUsers = managed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LuxuryTheme.backgroundGradient,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              // Premium Dark Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: LuxuryTheme.midnightBlue,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxuryTheme.glassBorder),
                  ),
                  child: IconButton(
                    icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
                      child: Container(
                        decoration: const BoxDecoration(
                           gradient: LuxuryTheme.backgroundGradient, // Seamless gradient
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: LuxuryTheme.cyanNeon.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: LuxuryTheme.cyanNeon.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _adminName.isNotEmpty
                                              ? _adminName[0].toUpperCase()
                                              : 'A',
                                          style: GoogleFonts.outfit(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: LuxuryTheme.cyanNeon,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _adminName,
                                            style: GoogleFonts.prompt(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _adminPhone,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: LuxuryTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
  
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Cards Row
                      _buildInfoCards(),
                      const SizedBox(height: 24),
  
                      // Managed Users Section
                      _buildSectionHeader(
                        'ผู้ใช้ในความดูแล',
                        '${_managedUsers.length} คน',
                      ),
                      const SizedBox(height: 12),
                      _buildManagedUsersList(),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
  
          // Assign Users FAB
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
            child: FloatingActionButton.extended(
              onPressed: _showAssignUsersDialog,
              backgroundColor: LuxuryTheme.purpleNeon,
              elevation: 0,
              icon: const HeroIcon(HeroIcons.userPlus, color: Colors.white, size: 20),
              label: Text(
                'มอบหมาย User',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    String locationStr = '';
    if (_district != null && _district!.isNotEmpty) {
      locationStr = 'อ.$_district';
      if (_province != null && _province!.isNotEmpty) {
        locationStr += ' จ.$_province';
      }
    } else if (_province != null && _province!.isNotEmpty) {
      locationStr = 'จ.$_province';
    }

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'พื้นที่ดูแล',
            locationStr.isNotEmpty ? locationStr : 'ไม่ระบุ',
            HeroIcons.mapPin,
            LuxuryTheme.goldNeon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'ภูมิภาค',
            _region ?? 'ไม่ระบุ',
            HeroIcons.globeAlt,
            LuxuryTheme.cyanNeon,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    HeroIcons icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxuryTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxuryTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: HeroIcon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 12,
              color: LuxuryTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: LuxuryTheme.purpleNeon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LuxuryTheme.purpleNeon.withOpacity(0.3)),
          ),
          child: Text(
            subtitle,
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: LuxuryTheme.purpleNeon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagedUsersList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: LuxuryTheme.cyanNeon,
          ),
        ),
      );
    }

    if (_managedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: LuxuryTheme.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LuxuryTheme.glassBorder),
        ),
        child: Column(
          children: [
            const HeroIcon(
              HeroIcons.userGroup,
              size: 48,
              color: LuxuryTheme.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีผู้ใช้ในความดูแล',
              style: GoogleFonts.prompt(
                color: LuxuryTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กด "มอบหมาย User" เพื่อเพิ่ม',
              style: GoogleFonts.prompt(
                color: LuxuryTheme.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _managedUsers.map((user) {
        final String userId = user['id'] ?? '';
        final String firstName = user['firstName'] ?? '';
        final String lastName = user['lastName'] ?? '';
        final String phone = user['phone'] ?? '';
        final String fullName = '$firstName $lastName'.trim();

        final String membershipStatus = user['membershipStatus'] ?? 'NONE';
        
        Color badgeColor;
        String badgeText;
        switch (membershipStatus.toUpperCase()) {
          case 'APPROVED':
            badgeColor = LuxuryTheme.emeraldNeon;
            badgeText = 'สถานะปกติ';
            break;
          case 'PENDING':
            badgeColor = LuxuryTheme.goldNeon;
            badgeText = 'รออนุมัติ';
            break;
          case 'REJECTED':
            badgeColor = Colors.redAccent;
            badgeText = 'ถูกปฏิเสธ';
            break;
          default:
            badgeColor = Colors.grey;
            badgeText = 'ไม่สังกัดกลุ่ม';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: LuxuryTheme.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LuxuryTheme.glassBorder),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: LuxuryTheme.purpleNeon.withOpacity(0.1),
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: LuxuryTheme.purpleNeon,
                ),
              ),
            ),
            title: Text(
              fullName,
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: LuxuryTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.prompt(
                      fontSize: 10,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const HeroIcon(
                HeroIcons.arrowsRightLeft,
                size: 20,
                color: LuxuryTheme.goldNeon,
              ),
              tooltip: 'ย้ายไปยัง Admin อื่น',
              onPressed: () => _showReassignDialog(userId, fullName),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showAssignUsersDialog() async {
    setState(() => _isProcessing = true);
    try {
      final service = context.read<SuperAdminService>();
      
      // Get all admins to find already-assigned user IDs from getAdminList
      final response = await service.getAdminList();
      final Set<String> assignedIds = {};
      for (final admin in response) {
        final managed = admin['managedUsers'] as List? ?? [];
        for (final u in managed) {
          assignedIds.add(u['id'] ?? '');
        }
      }
      
      // Refresh all users if not already loaded
      if (_allUsers.isEmpty) {
        _allUsers = await service.getUsers();
      }
      
      // Fallback: Also check managedByAdminId from _allUsers directly
      for (final u in _allUsers) {
        if (u is Map && (u['managedByAdminId'] != null || u['adminId'] != null)) {
           assignedIds.add(u['id'] ?? '');
        }
      }
      
      // Filter: only role=USER (farmer), not already assigned, not admin/superadmin
      final unassignedUsers = _allUsers.where((u) {
        final id = u is Map ? (u['id'] ?? '') : '';
        final role = u is Map ? (u['role']?.toString().toUpperCase() ?? '') : '';
        return !assignedIds.contains(id) && (role == 'USER' || role == 'FARMER');
      }).toList();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final List<String> selectedIds = [];

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: LuxuryTheme.cyanNeon, width: 1)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.userPlus,
                        color: LuxuryTheme.purpleNeon,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'มอบหมาย User ให้ $_adminName',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: unassignedUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HeroIcon(
                                HeroIcons.userGroup,
                                size: 48,
                                color: LuxuryTheme.textDisabled,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ไม่มี User ที่สามารถมอบหมายได้',
                                style: GoogleFonts.prompt(
                                  color: LuxuryTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ทั้งหมดถูกมอบหมายแล้ว',
                                style: GoogleFonts.prompt(
                                  color: LuxuryTheme.textDisabled,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: unassignedUsers.length,
                          itemBuilder: (context, index) {
                            final user = unassignedUsers[index];
                            final id = user['id'] ?? '';
                            final name =
                                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                    .trim();
                            final phone = user['phone'] ?? '';
                            final isSelected = selectedIds.contains(id);

                            return Theme(
                              data: ThemeData(unselectedWidgetColor: Colors.white54),
                              child: CheckboxListTile(
                                value: isSelected,
                                activeColor: LuxuryTheme.purpleNeon,
                                checkColor: Colors.white,
                                title: Text(
                                  name,
                                  style: GoogleFonts.prompt(fontSize: 14, color: Colors.white),
                                ),
                                subtitle: Text(
                                  phone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: LuxuryTheme.textSecondary,
                                  ),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedIds.add(id);
                                    } else {
                                      selectedIds.remove(id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: LuxuryTheme.neonShadow(LuxuryTheme.purpleNeon),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () => Navigator.pop(context),
                        icon: const HeroIcon(
                          HeroIcons.check,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          'มอบหมาย ${selectedIds.length} คน',
                          style: GoogleFonts.prompt(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuxuryTheme.purpleNeon,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedIds.isNotEmpty) {
        await _assignUsers(selectedIds);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AdminErrorHandler.handle(context, e, operation: 'โหลดรายชื่อ');
      }
    }
  }

  Future<void> _assignUsers(List<String> userIds) async {
    setState(() => _isProcessing = true);
    try {
      final service = context.read<SuperAdminService>();
      await service.assignUsersToAdmin(_adminId, userIds);
      if (!mounted) return;
      AdminErrorHandler.showSuccess(
        context,
        message: 'มอบหมาย ${userIds.length} คนสำเร็จ',
        detail: 'User ถูกเพิ่มเข้าความดูแลของ $_adminName แล้ว',
      );
      _loadData(); 
    } catch (e) {
      if (!mounted) return;
      AdminErrorHandler.handle(context, e, operation: 'มอบหมาย User');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showReassignDialog(String userId, String userName) async {
    try {
      final service = context.read<SuperAdminService>();
      final admins = await service.getAdminList();

      if (!mounted) return;

      final otherAdmins =
          admins.where((a) => a['id'] != _adminId).toList();

      if (otherAdmins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่มี Admin อื่นในระบบ',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      String? selectedAdminId;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: LuxuryTheme.glassBorder),
            ),
            title: Row(
              children: [
                const HeroIcon(
                  HeroIcons.arrowsRightLeft,
                  color: LuxuryTheme.goldNeon,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ย้าย $userName',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เลือก Admin ปลายทาง:',
                    style: GoogleFonts.outfit(
                      color: LuxuryTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...otherAdmins.map((admin) {
                    final id = admin['id'] ?? '';
                    final name =
                        '${admin['firstName'] ?? ''} ${admin['lastName'] ?? ''}'
                            .trim();
                    final count = admin['managedUsersCount'] ?? 0;
                    return Theme(
                       data: ThemeData(unselectedWidgetColor: Colors.white54),
                       child: RadioListTile<String>(
                        value: id,
                        groupValue: selectedAdminId,
                        activeColor: LuxuryTheme.goldNeon,
                        title: Text(name, style: GoogleFonts.prompt(color: Colors.white)),
                        subtitle: Text(
                          '$count คนในความดูแล',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: LuxuryTheme.textSecondary,
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(
                              () => selectedAdminId = value);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: selectedAdminId != null
                    ? () => Navigator.pop(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuxuryTheme.goldNeon,
                ),
                child: Text(
                  'ย้าย',
                  style: GoogleFonts.prompt(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      if (selectedAdminId != null) {
        setState(() => _isProcessing = true);
        try {
          await service.reassignUser(
            userId: userId,
            newAdminId: selectedAdminId!,
          );
          if (!mounted) return;
          AdminErrorHandler.showSuccess(
            context,
            message: 'ย้าย $userName สำเร็จ',
          );
          _loadData();
        } catch (e) {
          if (!mounted) return;
          AdminErrorHandler.handle(context, e, operation: 'ย้าย User');
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AdminErrorHandler.handle(context, e, operation: 'โหลดรายชื่อ Admin');
      }
    }
  }
}
