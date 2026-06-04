import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/plot_model.dart';
import '../../map/screens/map_drawing_screen.dart';
import '../../gap/screens/plot_gallery_screen.dart'; // Added
import 'admin_gap_inspection_screen.dart';

/// Admin Plot List Screen - แสดงรายการแปลง (ทั้งหมด หรือ กรองตาม User)
class AdminPlotListScreen extends StatefulWidget {
  final String? userId; // Optional: กรองเฉพาะ User นี้
  final String? userName; // Optional: ชื่อ User เพื่อแสดงใน Header
  final String? initialStatusFilter; // Optional: filter เริ่มต้น (PENDING, APPROVED, REJECTED)

  const AdminPlotListScreen({
    super.key,
    this.userId,
    this.userName,
    this.initialStatusFilter,
  });

  @override
  State<AdminPlotListScreen> createState() => _AdminPlotListScreenState();
}

class _AdminPlotListScreenState extends State<AdminPlotListScreen> {
  bool _isLoading = true;
  List<dynamic> _allPlots = [];
  List<dynamic> _filteredPlots = [];
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter; // Apply initial filter if provided
    _loadPlots();
  }

  Future<void> _loadPlots() async {
    setState(() => _isLoading = true);
    try {
      final adminService = context.read<AdminService>();
      // Use server-side filtering with userId
      final plots = await adminService.getAdminPlots(userId: widget.userId);

      if (mounted) {
        setState(() {
          // Fallback: filter client-side in case backend ignores userId query param
          if (widget.userId != null) {
            final targetId = widget.userId.toString();
            _allPlots = plots.where((plot) {
              final ownerId = plot['userId']?.toString() ??
                  plot['ownerId']?.toString() ??
                  (plot['owner'] is Map ? plot['owner']['id']?.toString() : null) ??
                  (plot['owner'] is Map ? plot['owner']['_id']?.toString() : null);
              return ownerId == targetId;
            }).toList();
          } else {
            _allPlots = plots;
          }
          // Just apply local search/status filters
          _filterPlots();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  void _filterPlots() {
    setState(() {
      _filteredPlots = _allPlots.where((plot) {
        // Status Filter
        if (_statusFilter != null && plot['status'] != _statusFilter) {
          return false;
        }

        // Search Filter
        if (_searchQuery.isNotEmpty) {
          final name = (plot['name'] ?? '').toString().toLowerCase();
          final species = (plot['species'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || species.contains(query);
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userName != null
        ? 'แปลงของ ${widget.userName}'
        : 'รายการแปลงเกษตร';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary.withOpacity(0.1), Colors.white],
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // AppBar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: HeroIcon(
                          HeroIcons.arrowLeft,
                          color: Colors.grey[800],
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Filters
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'ค้นหาชื่อแปลง, พืช...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              onChanged: (value) {
                                _searchQuery = value;
                                _filterPlots();
                              },
                            ),
                            const SizedBox(height: 12),
                            // Status Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('ทั้งหมด', null),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'รอตรวจสอบ',
                                    'PENDING',
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'อนุมัติแล้ว',
                                    'APPROVED',
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'ปฏิเสธ',
                                    'REJECTED',
                                    color: AppColors.error,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : _filteredPlots.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: _filteredPlots.length,
                                itemBuilder: (context, index) {
                                  return _buildPlotCard(_filteredPlots[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, {Color? color}) {
    final isSelected = _statusFilter == value;
    final displayColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? value : null;
          _filterPlots();
        });
      },
      selectedColor: displayColor.withOpacity(0.2),
      checkmarkColor: displayColor,
      labelStyle: GoogleFonts.prompt(
        color: isSelected ? displayColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? displayColor : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(HeroIcons.map, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบข้อมูลแปลงเกษตร',
            style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotCard(dynamic plot) {
    final status = plot['status'] ?? '';
    Color statusColor = Colors.grey;
    String statusText = 'ไม่ระบุ';

    if (status == 'PENDING') {
      statusColor = Colors.orange;
      statusText = 'รอตรวจสอบ';
    } else if (status == 'APPROVED') {
      statusColor = AppColors.success;
      statusText = 'อนุมัติแล้ว';
    } else if (status == 'REJECTED') {
      statusColor = AppColors.error;
      statusText = 'ถูกปฏิเสธ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to GAP Inspection
            final owner = plot['owner'] != null
                ? UserModel.fromJson(plot['owner'])
                : null;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminGapInspectionScreen(
                  plotId: plot['id'].toString(),
                  plotName: plot['name'] ?? 'ไม่ระบุชื่อ',
                  owner: owner,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HeroIcon(HeroIcons.map, color: statusColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot['name'] ?? 'ไม่ระบุชื่อ',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.grass, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                plot['species'] ?? '-',
                                style: GoogleFonts.prompt(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${(double.tryParse(plot['areaRai']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} ไร่',
                                style: GoogleFonts.prompt(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.prompt(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                // Gallery Button
                IconButton(
                  icon: const HeroIcon(
                    HeroIcons.photo,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: 'ดูรูปแปลง',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlotGalleryScreen(
                          plotId: plot['id'].toString(),
                          plotName: plot['name'] ?? 'ไม่ระบุชื่อ',
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                // Edit Button - ซ่อนถ้าแปลง APPROVED แล้ว
                if (status != 'APPROVED')
                  IconButton(
                    icon: const HeroIcon(
                      HeroIcons.pencilSquare,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    tooltip: 'แก้ไขพิกัดแปลง',
                    onPressed: () {
                      // Convert Map to PlotModel
                      final plotModel = PlotModel.fromJson(plot);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapDrawingScreen(
                            plotToEdit: plotModel,
                            isAdmin: true,
                          ),
                        ),
                      ).then((_) => _loadPlots()); // Reload after edit
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
