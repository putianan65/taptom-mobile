import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/env.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../data/models/user_model.dart';
import 'admin_gap_inspection_screen.dart';
import 'create_plot_for_user_screen.dart';
import '../../auth/auth_provider.dart';
import '../../../data/models/plot_model.dart';
import 'plot_editor_screen_maplibre.dart';

/// ✨ IMPROVED Admin Plots Map Screen
/// - Modern marker design with gradient & icons
/// - Compact drawer (70% width)
/// - Cleaner BottomSheet with better spacing
/// - Proper number formatting (1-2 decimal places)
class AdminPlotsMapScreen extends StatefulWidget {
  final String? userId; // Optional: Filter by user
  final bool isMainTab; // ✅ New: Hide back button if main tab

  const AdminPlotsMapScreen({
    super.key, 
    this.userId,
    this.isMainTab = false,
  });

  @override
  State<AdminPlotsMapScreen> createState() => _AdminPlotsMapScreenState();
}

class _AdminPlotsMapScreenState extends State<AdminPlotsMapScreen> {
  MaplibreMapController? _mapController;
  String get _styleUrl =>
      'https://api.maptiler.com/maps/satellite/style.json?key=${Env.mapTilerApiKey}';

  List<dynamic> _plots = [];
  bool _isLoading = true;
  bool _locationEnabled = false;
  bool _isStyleLoaded = false; // ✅ Track if map style is ready
  String? _selectedStatus;
  
  // 🎨 Modern Marker Names
  static const String markerPending = 'marker_PENDING';
  static const String markerApproved = 'marker_APPROVED';
  static const String markerRejected = 'marker_REJECTED';
  static const String markerDefault = 'marker_DEFAULT';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadPlots();
  }

  @override
  void dispose() {
    _mapController?.onFillTapped.remove(_onFillTapped);
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final granted = await PermissionUtils.requestLocationPermission(context);
    if (mounted) {
      setState(() => _locationEnabled = granted);
    }
  }

  Future<void> _loadPlots() async {
    final adminService = context.read<AdminService>();
    
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Plots
      final plots = await adminService.getAdminPlots(
        status: _selectedStatus,
        userId: widget.userId,
      );

      // 2. Fetch Users (for manual joining if owner data is missing)
      Map<String, dynamic> userMap = {};
      try {
        final users = await adminService.getUsers();
        for (var user in users) {
          if (user.id != null) {
            userMap[user.id!] = user.toJson();
          }
        }
      } catch (e) {
        print('⚠️ Could not fetch users for mapping: $e');
      }

      // 3. Enrich Plots with Owner Data
      final enrichedPlots = plots.map((plot) {
        // If owner is missing, look up by userId or ownerId
        if (plot['owner'] == null && plot['user'] == null) {
           final ownerId = plot['userId'] ?? plot['ownerId'];
           if (ownerId != null && userMap.containsKey(ownerId)) {
             // Create a new map to avoid modifying read-only data if any
             final newPlot = Map<String, dynamic>.from(plot);
             newPlot['owner'] = userMap[ownerId];
             return newPlot;
           }
        }
        return plot;
      }).toList();

      if (!mounted) return;
      
      setState(() {
        _plots = enrichedPlots;
        _isLoading = false;
      });
      // ✅ Only update map if style is ready (prevents Annotation Manager error)
      if (_isStyleLoaded) {
        _updateMap();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลแปลงไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _onMapCreated(MaplibreMapController controller) async {
    _mapController = controller;
    _mapController!.onFillTapped.add(_onFillTapped);
    _mapController!.onSymbolTapped.add(_onSymbolTapped);
    
    print('✅ Map created successfully');
  }

  void _onStyleLoaded() async {
    print('✅ Map style loaded');
    try {
       // 🎨 Register Modern Marker Images
       await _registerModernMarker(markerPending, const Color(0xFFFF9800), PhosphorIconsRegular.clock);
       await _registerModernMarker(markerApproved, const Color(0xFF4CAF50), PhosphorIconsRegular.checkCircle);
       await _registerModernMarker(markerRejected, const Color(0xFFF44336), PhosphorIconsRegular.xCircle);
       await _registerModernMarker(markerDefault, const Color(0xFF9E9E9E), PhosphorIconsRegular.mapPin);
       print('✅ Modern marker images registered');
    } catch (e) {
      print('❌ Error registering markers: $e');
    }

    // ✅ Mark style as loaded BEFORE updating map
    if (mounted) {
      setState(() => _isStyleLoaded = true);
    }
    _updateMap();
  }

  /// 🎨 Generate Modern Marker with Gradient & Icon
  Future<void> _registerModernMarker(String name, Color color, IconData icon) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(80, 80);
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. Shadow/Glow Effect
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 28, shadowPaint);

    // 2. Gradient Background
    final gradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        24,
        [color.withValues(alpha: 0.95), color],
        [0.0, 1.0],
      );
    canvas.drawCircle(center, 24, gradientPaint);

    // 3. White Border Ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 24, borderPaint);
    
    // 4. Inner White Circle (for icon background)
    final innerCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 14, innerCirclePaint);

    // 5. Draw Icon (simplified as circle with smaller colored dot)
    final iconPaint = Paint()..color = color;
    canvas.drawCircle(center, 10, iconPaint);
    
    // 6. Subtle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(center.dx - 8, center.dy - 8), 6, highlightPaint);

    // Convert to Image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      await _mapController?.addImage(name, byteData.buffer.asUint8List());
    }
  }

  void _updateMap() async {
    // ✅ Guard: Don't update if map or style isn't ready
    if (_mapController == null || !_isStyleLoaded) return;
    if (_plots.isEmpty) return;

    try {
      await _mapController!.clearFills();
      await _mapController!.clearSymbols();

      double? minLat, maxLat, minLng, maxLng;

      for (var plot in _plots) {
        final geometry = plot['geometry'];
        final boundary = _parseBoundary(geometry);
        if (boundary.isEmpty) continue;

        // Determine color & icon based on status
        String color = AppColors.primary.toHexStringRGB();
        String iconImage = markerDefault;
        final status = plot['status'] ?? '';

        if (status == 'PENDING') {
          color = '#FF9800'; // Material Orange 500
          iconImage = markerPending;
        } else if (status == 'REJECTED') {
          color = '#F44336'; // Material Red 500
          iconImage = markerRejected;
        } else if (status == 'APPROVED') {
          color = '#4CAF50'; // Material Green 500
          iconImage = markerApproved;
        }

        // Add Fill (Polygon)
        await _mapController!.addFill(
          FillOptions(
            geometry: [boundary],
            fillColor: color,
            fillOpacity: 0.35, // ลดความทึบลงเล็กน้อย
            fillOutlineColor: '#FFFFFF',
          ),
          {'plotId': plot['id']},
        );
        
        // Add Symbol (Modern Marker) at Centroid
        final centroid = _calculateCentroid(boundary);
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: centroid,
            iconImage: iconImage,
            iconSize: 0.8, // ลดขนาดลงเล็กน้อยให้ดูไม่อึดอัด
            iconAnchor: 'center',
          ),
          {'plotId': plot['id']},
        );

        // Expand bounds
        for (var point in boundary) {
          if (minLat == null || point.latitude < minLat) minLat = point.latitude;
          if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
          if (minLng == null || point.longitude < minLng) minLng = point.longitude;
          if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
        }
      }

      if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
        if (!mounted) return;
        
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            left: 50, right: 50, top: 50, bottom: 120,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating map: $e');
    }
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0;
    double lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  List<LatLng> _parseBoundary(dynamic geometry) {
    if (geometry == null) return [];
    try {
      if (geometry is Map && geometry['coordinates'] is List) {
        final coords = geometry['coordinates'] as List;
        if (coords.isEmpty) return [];
        final ring = coords[0] as List; 
        return ring.map<LatLng>((point) {
          if (point is List && point.length >= 2) {
            final lng = (point[0] as num).toDouble();
            final lat = (point[1] as num).toDouble();
            return LatLng(lat, lng);
          }
          return const LatLng(0, 0);
        }).where((p) => p.latitude != 0 || p.longitude != 0).toList();
      }
    } catch (e) {
      print('❌ Error parsing boundary: $e');
    }
    return [];
  }
  
  void _onSymbolTapped(Symbol symbol) {
     final plotId = symbol.data?['plotId'];
     if (plotId != null) {
        _findAndShowPlot(plotId);
     }
  }

  void _onFillTapped(Fill fill) {
    final plotId = fill.data?['plotId'];
    if (plotId != null) {
      _findAndShowPlot(plotId);
    }
  }

  void _findAndShowPlot(String plotId) {
    Map<String, dynamic>? plot;
    try {
      plot = _plots.firstWhere(
        (p) => p['id'] == plotId,
        orElse: () => <String, dynamic>{}, 
      ) as Map<String, dynamic>?;
      
      if (plot == null || plot.isEmpty) return;
      _showPlotInfo(plot);
    } catch (e) {
      print('❌ Error finding plot: $e');
    }
  }

  void _showPlotInfo(Map<String, dynamic> initialPlotData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PlotDetailSheet(
        initialData: initialPlotData,
        onPlotUpdated: _loadPlots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFAB(),
      endDrawer: _SidePlotList(
        plots: _plots,
        onPlotSelected: (plot) {
          Navigator.pop(context);
          _findAndShowPlot(plot['id']);
        },
      ),
      body: Stack(
        children: [
          MaplibreMap(
            styleString: _styleUrl,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7, 100.5),
              zoom: 5,
            ),
            myLocationEnabled: _locationEnabled,
            myLocationRenderMode: MyLocationRenderMode.normal,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (!_isLoading) _buildStatsOverlay(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'แผนที่แปลงทั้งหมด',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      automaticallyImplyLeading: !widget.isMainTab, // ✅ Hide auto back button
      leading: widget.isMainTab
          ? null // If main tab, no leading
          : IconButton(
              icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.black),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin/dashboard');
                }
              },
            ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(PhosphorIconsRegular.funnelSimple, color: Colors.black),
          onSelected: (value) {
            setState(() {
              _selectedStatus = value == 'ALL' ? null : value;
            });
            _loadPlots();
          },
          itemBuilder: (context) => [
            _buildFilterItem('ทั้งหมด', 'ALL', Colors.grey),
            _buildFilterItem('รอตรวจสอบ', 'PENDING', const Color(0xFFFF9800)),
            _buildFilterItem('ได้รับการรับรอง', 'APPROVED', const Color(0xFF4CAF50)),
          ],
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(PhosphorIconsRegular.listBullets, color: Colors.black),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'รายชื่อแปลง',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterItem(String text, String value, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(PhosphorIconsFill.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle()),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    final isSuperAdmin = context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin;
    final primaryColor = isSuperAdmin ? AppColors.superAdminPrimary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlotForUserScreen()), 
          ).then((_) => _loadPlots());
        },
        label: Text(
          'เพิ่มแปลงเกษตร',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white, size: 24),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 60, // Below AppBar
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildVerticalStatItem(
              count: _plots.length,
              color: Colors.grey[800]!,
              label: 'ทั้งหมด',
            ),
            const SizedBox(height: 12),
            _buildVerticalStatItem(
              count: _plots.where((p) => p['status'] == 'PENDING').length,
              color: const Color(0xFFFF9800),
              label: 'รอตรวจ',
            ),
            const SizedBox(height: 12),
            _buildVerticalStatItem(
              count: _plots.where((p) => p['status'] == 'APPROVED').length,
              color: const Color(0xFF4CAF50),
              label: 'อนุมัติ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalStatItem({
    required int count,
    required Color color,
    required String label,
  }) {
    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(-10, 0),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$label: $count แปลง',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

}

// ✨ IMPROVED: Compact Side Drawer (70% width)
class _SidePlotList extends StatelessWidget {
  final List<dynamic> plots;
  final Function(Map<String, dynamic>) onPlotSelected;

  const _SidePlotList({required this.plots, required this.onPlotSelected});

  /// 🎯 Helper: Format area with proper decimals
  String _formatArea(dynamic area) {
    if (area == null) return '0.0';
    final value = (area is num) ? area.toDouble() : double.tryParse(area.toString()) ?? 0.0;
    
    // ใช้ทศนิยม 1-2 ตำแหน่ง ตามความเหมาะสม
    if (value >= 100) {
      return value.toStringAsFixed(1); // 123.4 ไร่
    } else if (value >= 10) {
      return value.toStringAsFixed(1); // 12.3 ไร่
    } else {
      return value.toStringAsFixed(2); // 1.23 ไร่
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin;
    final primaryColor = isSuperAdmin ? AppColors.superAdminPrimary : AppColors.primary;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7, // 🎯 Compact 70%
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.listBullets, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'รายการแปลง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: plots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey[100]!,
                                Colors.grey[50]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.tray,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบข้อมูลแปลง',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ยังไม่มีแปลงในระบบ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: plots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final plot = plots[index];
                      final status = plot['status'] ?? '';
                      Color statusColor = Colors.grey;
                      String statusText = 'ไม่ระบุ';
                      IconData statusIcon = PhosphorIconsRegular.question;

                      if (status == 'PENDING') {
                        statusColor = const Color(0xFFFF9800);
                        statusText = 'รอตรวจ';
                        statusIcon = PhosphorIconsRegular.clock;
                      } else if (status == 'APPROVED') {
                        statusColor = const Color(0xFF4CAF50);
                        statusText = 'อนุมัติ';
                        statusIcon = PhosphorIconsFill.checkCircle;
                      } else if (status == 'REJECTED') {
                        statusColor = const Color(0xFFF44336);
                        statusText = 'ปฏิเสธ';
                        statusIcon = PhosphorIconsRegular.xCircle;
                      }

                      final owner = plot['owner'] ?? plot['user'];
                      final ownerName = owner != null
                          ? (owner['fullName'] ?? '${owner['firstName']} ${owner['lastName']}'.trim())
                          : 'ไม่ระบุเจ้าของ';

                      return InkWell(
                        onTap: () => onPlotSelected(plot),
                        borderRadius: BorderRadius.circular(16), // ⬆️ เพิ่มจาก 12 → 16
                        child: Container(
                          padding: const EdgeInsets.all(14), // ⬆️ เพิ่ม padding เล็กน้อย
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16), // ⬆️ เพิ่มจาก 12 → 16
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Status Icon
                              Container(
                                width: 44, // ⬆️ เพิ่มจาก 40
                                height: 44, // ⬆️ เพิ่มจาก 40
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withValues(alpha: 0.15),
                                      statusColor.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12), // ⬆️ เพิ่มจาก 8
                                ),
                                child: Icon(statusIcon, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 10),
                              
                              // Plot Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plot['name'] ?? 'ไม่มีชื่อ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ownerName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Area & Status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_formatArea(plot['areaRai'])} ไร่',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          statusColor.withValues(alpha: 0.15),
                                          statusColor.withValues(alpha: 0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8), // ⬆️ เพิ่มจาก 4
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


// ✨ IMPROVED: Cleaner Plot Detail Sheet
class _PlotDetailSheet extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onPlotUpdated;

  const _PlotDetailSheet({
    required this.initialData,
    required this.onPlotUpdated,
  });

  @override
  State<_PlotDetailSheet> createState() => _PlotDetailSheetState();
}

class _PlotDetailSheetState extends State<_PlotDetailSheet> {
  late Map<String, dynamic> _plot;
  bool _isLoading = true;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _plot = widget.initialData;
    _fetchFullDetails();
  }

  /// 🎯 Helper: Format area with proper decimals
  String _formatArea(dynamic area) {
    if (area == null) return '0.0';
    final value = (area is num) ? area.toDouble() : double.tryParse(area.toString()) ?? 0.0;
    
    if (value >= 100) {
      return value.toStringAsFixed(1);
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Future<void> _fetchFullDetails() async {
    try {
      final adminService = context.read<AdminService>();
      final fullData = await adminService.getPlotDetail(_plot['id']);

      // ✅ FIX: Manually fetch owner if backend fails to include it
      final ownerData = fullData['owner'] ?? fullData['user'];
      final ownerId = fullData['ownerId'] ?? fullData['userId'];

      if (ownerData == null && ownerId != null) {
        try {
          final ownerUser = await adminService.getUserDetails(ownerId);
          fullData['owner'] = ownerUser.toJson();
        } catch (e) {
          print('⚠️ Cannot fetch owner details: $e');
        }
      }

      if (mounted) {
        setState(() {
          if (fullData.isNotEmpty) {
             // Merge with existing data to prevent data loss
            _plot = {..._plot, ...fullData};
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleApprove() async {
     setState(() => _isProcessingAction = true);
     try {
       final ownerId = (_plot['owner']?['id'] ?? _plot['ownerId'] ?? _plot['userId'])?.toString();
       final plotName = _plot['name']?.toString();
       await context.read<AdminService>().approvePlot(
         _plot['id'],
         ownerId: ownerId,
         plotName: plotName,
       );
       if (!mounted) return;
       
       setState(() {
          _plot['status'] = 'APPROVED';
          _isProcessingAction = false;
       });
       widget.onPlotUpdated();
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('✅ อนุมัติแปลง ${_plot['name']} เรียบร้อย'),
           backgroundColor: const Color(0xFF4CAF50),
         ),
       );
     } catch (e) {
       setState(() => _isProcessingAction = false);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
       );
     }
  }

  Future<void> _handleReject() async {
     final reasonController = TextEditingController();
     final reason = await showDialog<String>(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'ระบุเหตุผลที่ปฏิเสธ',
           style: TextStyle(fontWeight: FontWeight.bold),
         ),
         content: TextField(
           controller: reasonController,
           decoration: InputDecoration(
             hintText: 'เช่น ข้อมูลพื้นที่ไม่ถูกต้อง, เอกสารไม่ครบ',
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
           ),
           maxLines: 3,
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context), 
             child: Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
           ),
           ElevatedButton(
             onPressed: () => Navigator.pop(context, reasonController.text),
             style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFFF44336),
             ),
             child: Text(
               'ยืนยันปฏิเสธ',
               style: TextStyle(color: Colors.white),
             ),
           ),
         ],
       ),
     );
     
     if (reason == null || reason.trim().isEmpty) return;

     setState(() => _isProcessingAction = true);
     try {
       final ownerId = (_plot['owner']?['id'] ?? _plot['ownerId'] ?? _plot['userId'])?.toString();
       final plotName = _plot['name']?.toString();
       await context.read<AdminService>().rejectPlot(
         _plot['id'],
         reason,
         ownerId: ownerId,
         plotName: plotName,
       );
       if (!mounted) return;
       
       setState(() {
          _plot['status'] = 'REJECTED';
          _isProcessingAction = false;
       });
       widget.onPlotUpdated();
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: const Text('❌ ปฏิเสธแปลงเรียบร้อย'),
            backgroundColor: Colors.grey[800],
         ),
       );
     } catch (e) {
       setState(() => _isProcessingAction = false);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
       );
     }
  }
  
  void _openGapInspection() {
    Navigator.pop(context);
    
    UserModel? owner;
    try {
      if (_plot['owner'] != null) {
        // Ensure it's not just an ID string or empty map
        if (_plot['owner'] is Map && (_plot['owner'] as Map).isNotEmpty) {
           owner = UserModel.fromJson(_plot['owner']);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing owner for GAP inspection: $e');
      // Pass null, let screen fetch it
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminGapInspectionScreen(
          plotId: _plot['id'].toString(),
          plotName: _plot['name'] ?? 'ไม่ระบุชื่อ',
          owner: owner,
        ),
      ),
    );
  }

  Future<void> _navigateToEditor() async {
    // Convert Map to PlotModel
    try {
      final plotModel = PlotModel.fromJson(_plot);
      
      final updatedPlot = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlotEditorScreenMapLibre(plot: plotModel),
        ),
      );

      if (updatedPlot != null && updatedPlot is PlotModel && mounted) {
        setState(() {
           // Update local state with new geometry
           _plot['geometry'] = updatedPlot.geometry;
           // If area or other fields changed, update them too if needed
        });
        widget.onPlotUpdated(); // Refresh parent map
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดตัวแก้ไขได้: $e')),
      );
    }
  }

  bool _canEditPlot() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return false;
    
    // Super Admin has full access
    if (user.role == UserRole.superAdmin) return true;
    
    // Admin checks territory
    if (user.role == UserRole.admin) {
      return _isInTerritory(user, _plot);
    }
    
    return false;
  }

  bool _isInTerritory(UserModel user, Map<String, dynamic> plot) {
    // Check if plot is in admin's territory (Hierarchy: SubDistrict -> District -> Province -> Region)
    
    // Fallback: If plot has no location data (e.g. new pending plot), check Owner's location
    Map<String, dynamic> targetLocation = plot;
    if (plot['province'] == null && (plot['owner'] ?? plot['user']) != null) {
       targetLocation = plot['owner'] ?? plot['user'];
    }

    if (user.subdistrict != null) {
      return targetLocation['subDistrict'] == user.subdistrict;
    }
    if (user.district != null) {
      return targetLocation['district'] == user.district;
    }
    if (user.province != null) {
      return targetLocation['province'] == user.province;
    }
    if (user.region != null) {
      return targetLocation['region'] == user.region;
    }
    
    // If Admin has no territory assigned, they can't edit anything (safe default)
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessingAction) {
       return Container(
         height: 200,
         decoration: const BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
         ),
         child: const Center(
           child: CircularProgressIndicator(color: AppColors.primary),
         ),
       );
    }

    final owner = _plot['owner'] ?? _plot['user'];
    
    String ownerName;
    if (_isLoading) {
      ownerName = 'กำลังโหลด...';
    } else if (owner != null) {
      ownerName = owner['fullName'] ?? 
          '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim();
      if (ownerName.isEmpty) ownerName = 'ไม่พบข้อมูล';
    } else {
      ownerName = 'ไม่พบข้อมูลเจ้าของ';
    }
    
    final ownerPhone = owner != null ? (owner['phone'] ?? '-') : '-';

    String statusText = 'ไม่ระบุ';
    Color statusColor = Colors.grey;
    final status = _plot['status'] ?? '';

    if (status == 'PENDING') {
      statusText = 'รอตรวจสอบ';
      statusColor = const Color(0xFFFF9800);
    } else if (status == 'APPROVED') {
      statusText = 'ได้รับการรับรอง';
      statusColor = const Color(0xFF4CAF50);
    } else if (status == 'REJECTED') {
      statusText = 'ถูกปฏิเสธ';
      statusColor = const Color(0xFFF44336);
    }

    // Determine role color
    final isSuperAdmin = context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin;
    final primaryColor = isSuperAdmin ? AppColors.superAdminPrimary : AppColors.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header: Name & Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plot['name'] ?? 'แปลงไม่มีชื่อ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.plant, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _plot['species'] ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(PhosphorIconsRegular.ruler, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatArea(_plot['areaRai'])} ไร่',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Owner Info - Compact Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[50]!,
                  Colors.grey[100]!.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      ownerName.isNotEmpty ? ownerName[0] : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ownerPhone != '-')
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.phone,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ownerPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // GAP Report (Primary)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _openGapInspection,
                  icon: const Icon(
                    PhosphorIconsRegular.clipboardText,
                    color: Colors.white,
                    size: 20),
                  label: Text(
                    'ดูรายงาน GAP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // ✅ Edit Boundary - FIX: if statement ที่ถูกต้อง
              if (_canEditPlot())
                Expanded(
                  child: OutlinedButton(
                    onPressed: _navigateToEditor,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.notePencil,
                      color: Colors.grey,
                      size: 20),
                  ),
                ),
            ],
          ),
          
          // ✅ Approve/Reject Actions - Guarded by Permissions
          if (status == 'PENDING' && _canEditPlot()) ...[
             const SizedBox(height: 10),
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: _handleApprove,
                     icon: const Icon(
                       PhosphorIconsRegular.checkCircle,
                       color: Colors.white,
                       size: 18),
                     label: Text(
                       'อนุมัติ',
                       style: TextStyle(fontWeight: FontWeight.bold),
                     ),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF4CAF50),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(16),
                       ),
                       elevation: 2,
                       shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                     ),
                   ),
                 ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: _handleReject,
                     icon: const Icon(
                       PhosphorIconsRegular.xCircle,
                       color: Colors.white,
                       size: 18),
                     label: Text(
                       'ปฏิเสธ',
                       style: TextStyle(fontWeight: FontWeight.bold),
                     ),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFFF44336),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(16),
                       ),
                       elevation: 2,
                       shadowColor: const Color(0xFFF44336).withValues(alpha: 0.3),
                     ),
                   ),
                 ),
               ],
             ),
          ],
        ],
      ),
    );
  }
}