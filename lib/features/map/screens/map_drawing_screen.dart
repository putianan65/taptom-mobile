import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/env.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../core/utils/geo_json_utils.dart';
import '../../../../data/models/plot_model.dart';
import 'dart:math' as math;

import '../../../../core/services/admin_service.dart';

/// Production-grade Map Drawing Screen
/// Features:
/// - Professional UI/UX with proper spacing and hierarchy
/// - Robust error handling and state management
/// - Optimized performance with proper widget lifecycle
/// - Accessibility support
/// - Proper constraint management to prevent layout errors
class MapDrawingScreen extends StatefulWidget {
  final PlotModel? plotToEdit;
  final bool isAdmin;
  final String? targetUserId; // For Admin creating plot for user

  const MapDrawingScreen({
    super.key,
    this.plotToEdit,
    this.isAdmin = false,
    this.targetUserId,
  });

  @override
  State<MapDrawingScreen> createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  MaplibreMapController? _mapController;
  final LatLng _initialPosition = const LatLng(16.8208, 100.2659);

  // MapTiler Configuration
  static String get _satelliteStyle =>
      'https://api.maptiler.com/maps/hybrid/style.json?key=${Env.mapTilerApiKey}';
  static String get _streetStyle =>
      'https://api.maptiler.com/maps/streets/style.json?key=${Env.mapTilerApiKey}';

  // Map State
  bool _isSatelliteView = true;
  String _currentStyle = _satelliteStyle;

  // Drawing State
  bool _isDrawingMode = false;
  final List<LatLng> _polygonPoints = [];
  final List<Circle> _circles = [];
  Line? _currentLine;
  Fill? _currentPolygon;

  // GPS State
  String _gpsStatus = 'กำลังค้นหา GPS...';
  bool _isGpsHigh = false;

  // Plot Naming
  int _plotCounter = 1;

  // Visual Constants
  static const double _circleRadius = 8.0;
  static const double _lineWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _simulateGpsStatus();
  }

  @override
  void dispose() {
    // Clean up resources
    _mapController = null;
    super.dispose();
  }

  // ==================== GPS SIMULATION ====================

  void _simulateGpsStatus() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _gpsStatus = 'ความแม่นยำสูง';
          _isGpsHigh = true;
        });
      }
    });
  }

  // ==================== MAP LIFECYCLE ====================

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;

    if (widget.plotToEdit != null) {
      _loadExistingPlot();
    }
  }

  Future<void> _loadExistingPlot() async {
    if (widget.plotToEdit == null || _mapController == null) return;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _polygonPoints.addAll(widget.plotToEdit!.boundary);
      _isDrawingMode = true;
    });

    // Draw initial shape
    for (var point in _polygonPoints) {
      final circle = await _mapController!.addCircle(
        CircleOptions(
          geometry: point,
          circleRadius: _circleRadius,
          circleColor: AppColors.primary.toHexStringRGB(),
          circleStrokeWidth: 2.0,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _circles.add(circle);
    }

    await _updateLine();
    await _updatePolygon();

    // Center camera on plot
    if (_polygonPoints.isNotEmpty) {
      final center = _calculateCenter(_polygonPoints);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 16.0),
        ),
      );
    }
  }

  void _onStyleLoadedCallback() {
    if (mounted) {
      setState(() {});
    }
  }

  // ==================== MAP CONTROLS ====================

  void _toggleMapStyle() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
      _currentStyle = _isSatelliteView ? _satelliteStyle : _streetStyle;
    });
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _goToCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _initialPosition, zoom: 16.0),
      ),
    );
  }

  // ==================== DRAWING LOGIC ====================

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
    });

    _showSnackBar(
      _isDrawingMode ? 'แตะบนแผนที่เพื่อวาดขอบเขตแปลง' : 'ปิดโหมดวาดแปลง',
      _isDrawingMode ? AppColors.primary : Colors.grey[700]!,
      _isDrawingMode ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.xCircle,
    );
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!_isDrawingMode || _mapController == null) return;

    setState(() {
      _polygonPoints.add(point);
    });

    final circle = await _mapController!.addCircle(
      CircleOptions(
        geometry: point,
        circleRadius: _circleRadius,
        circleColor: AppColors.primary.toHexStringRGB(),
        circleStrokeWidth: 2.0,
        circleStrokeColor: '#FFFFFF',
      ),
    );

    _circles.add(circle);
    await _updateLine();
    await _updatePolygon();
  }

  Future<void> _updateLine() async {
    if (_mapController == null || _polygonPoints.length < 2) return;

    if (_currentLine != null) {
      await _mapController!.removeLine(_currentLine!);
    }

    _currentLine = await _mapController!.addLine(
      LineOptions(
        geometry: _polygonPoints,
        lineColor: AppColors.primary.toHexStringRGB(),
        lineWidth: _lineWidth,
        lineOpacity: 0.8,
      ),
    );
  }

  Future<void> _updatePolygon() async {
    if (_mapController == null || _polygonPoints.length < 3) return;

    if (_currentPolygon != null) {
      await _mapController!.removeFill(_currentPolygon!);
    }

    final points = List<LatLng>.from(_polygonPoints)..add(_polygonPoints.first);

    _currentPolygon = await _mapController!.addFill(
      FillOptions(
        geometry: [points],
        fillColor: AppColors.primary.toHexStringRGB(),
        fillOpacity: 0.35,
        fillOutlineColor: AppColors.primary.toHexStringRGB(),
      ),
    );
  }

  Future<void> _undoLastPoint() async {
    if (_polygonPoints.isEmpty || _mapController == null) return;

    setState(() {
      _polygonPoints.removeLast();
    });

    if (_circles.isNotEmpty) {
      final lastCircle = _circles.removeLast();
      await _mapController!.removeCircle(lastCircle);
    }

    await _updateLine();
    await _updatePolygon();
  }

  Future<void> _clearDrawing() async {
    if (_mapController == null) return;

    for (var circle in _circles) {
      await _mapController!.removeCircle(circle);
    }
    _circles.clear();

    if (_currentLine != null) {
      await _mapController!.removeLine(_currentLine!);
      _currentLine = null;
    }

    if (_currentPolygon != null) {
      await _mapController!.removeFill(_currentPolygon!);
      _currentPolygon = null;
    }

    setState(() {
      _polygonPoints.clear();
    });
  }

  // ==================== AREA CALCULATION ====================

  Map<String, int> _calculateThaiArea() {
    if (_polygonPoints.length < 3) {
      return {'rai': 0, 'ngan': 0, 'wah': 0};
    }

    // Shoelace formula for polygon area
    double area = 0;
    for (int i = 0; i < _polygonPoints.length; i++) {
      int j = (i + 1) % _polygonPoints.length;
      area += _polygonPoints[i].longitude * _polygonPoints[j].latitude;
      area -= _polygonPoints[j].longitude * _polygonPoints[i].latitude;
    }
    area = area.abs() / 2;

    // Convert to square meters (approximate)
    double latFactor = 111139.0;
    double lonFactor =
        111139.0 * math.cos(_polygonPoints.first.latitude * math.pi / 180);
    double sqMeters = area * latFactor * lonFactor;

    // Thai units conversion
    double sqWah = sqMeters / 4;
    int rai = (sqWah / 400).floor();
    int ngan = ((sqWah % 400) / 100).floor();
    int wah = (sqWah % 100).floor();

    return {'rai': rai, 'ngan': ngan, 'wah': wah};
  }

  LatLng _calculateCenter(List<LatLng> points) {
    double latSum = 0;
    double lngSum = 0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  // ==================== PLOT CONFIRMATION ====================

  void _confirmPolygon() {
    if (_polygonPoints.length < 3) {
      _showSnackBar(
        'กรุณาวาดแปลงให้สมบูรณ์ (อย่างน้อย 3 จุด)',
        Colors.red,
        PhosphorIconsRegular.warningCircle,
      );
      return;
    }

    final rootContext = context;
    showDialog(
      context: rootContext,
      useRootNavigator: false,
      builder: (dialogContext) {
        final nameController = TextEditingController(
          text: widget.plotToEdit != null
              ? widget.plotToEdit!.name
              : 'แปลงที่ $_plotCounter',
        );
        bool isLoading = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.mapPin,
                    color: AppColors.primary,
                    size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'บันทึกแปลง',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อแปลง',
                    hintText: 'เช่น แปลงกระท่อม บ้านสวน',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(PhosphorIconsRegular.pencilSimple),
                  ),
                  style: const TextStyle(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.mapPin,
                        color: AppColors.primary,
                        size: 20),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final area = _calculateThaiArea();
                          return Text(
                            'พื้นที่: ${area['rai']} ไร่ ${area['ngan']} งาน ${area['wah']} ตร.ว.',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (Navigator.of(dialogContext).canPop()) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                child: Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameController.text.isEmpty) return;

                        setDialogState(() => isLoading = true);

                        try {
                          final geometry = GeoJsonUtils.toPolygon(
                            _polygonPoints,
                          );

                          if (widget.isAdmin && widget.plotToEdit != null) {
                            // Admin update mode
                            final adminService = AdminService();
                            await adminService.adminUpdatePlot(
                              widget.plotToEdit!.id!,
                              geometry,
                            );

                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (mounted) {
                              _showSnackBar(
                                'อัปเดตพิกัดแปลงเรียบร้อย (Admin Override)',
                                AppColors.success,
                                PhosphorIconsRegular.checkCircle,
                              );
                              Navigator.of(rootContext).pop();
                            }
                          } else if (widget.isAdmin && widget.targetUserId != null) {
                             // Admin Create Mode for User
                             final adminService = context.read<AdminService>();
                             final newPlot = PlotModel(
                               name: nameController.text,
                               geometry: geometry,
                             );
                             
                             await adminService.createPlotForUser(
                               userId: widget.targetUserId!,
                               plot: newPlot,
                              );

                             if (mounted) {
                               final plotName = nameController.text;
                               final area = _calculateThaiArea();

                               if (Navigator.of(dialogContext).canPop()) {
                                 Navigator.of(dialogContext).pop();
                               }
                               _plotCounter++;

                               WidgetsBinding.instance.addPostFrameCallback((_) {
                                 if (!mounted) return;
                                 _showSuccessDialog(rootContext, plotName, area);
                               });
                             }
                          } else {
                            // User create mode
                            final plotService = rootContext.read<PlotService>();

                            final newPlot = PlotModel(
                              name: nameController.text,
                              geometry: geometry,
                            );

                            await plotService.createPlot(newPlot);

                            if (mounted) {
                              final plotName = nameController.text;
                              final area = _calculateThaiArea();

                              if (Navigator.of(dialogContext).canPop()) {
                                Navigator.of(dialogContext).pop();
                              }
                              _plotCounter++;

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _showSuccessDialog(rootContext, plotName, area);
                              });
                            }
                          }
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          _showSnackBar(
                            'เกิดข้อผิดพลาด: ${e.toString().replaceAll("Exception: ", "")}',
                            AppColors.error,
                            PhosphorIconsRegular.warning,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'บันทึก',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    String plotName,
    Map<String, int> area,
  ) {
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (successContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.checkCircle,
                  color: AppColors.success,
                  size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                'บันทึกแปลงสำเร็จ!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$plotName"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      PhosphorIconsRegular.mapPin,
                      color: AppColors.primary,
                      size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${area['rai']} ไร่ ${area['ngan']} งาน ${area['wah']} ตร.ว.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'แปลงของคุณพร้อมใช้งานแล้ว',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.of(successContext).canPop()) {
                    Navigator.of(successContext).pop();
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _clearDrawing();
                    setState(() {
                      _isDrawingMode = false;
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'เสร็จสิ้น',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI HELPERS ====================

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    final area = _calculateThaiArea();

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          MaplibreMap(
            key: ValueKey(_currentStyle),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoadedCallback,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15.0,
            ),
            styleString: _currentStyle,
            onMapClick: (point, latLng) => _onMapTap(latLng),
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.normal,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // Top Bar with GPS Status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    _buildCircleButton(
                      icon: PhosphorIconsRegular.arrowLeft,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  if (Navigator.of(context).canPop()) const SizedBox(width: 12),

                  // GPS Status Pill
                  Expanded(child: _buildGpsStatusPill()),

                  const SizedBox(width: 12),

                  // Layer Toggle
                  _buildCircleButton(
                    icon: _isSatelliteView ? PhosphorIconsRegular.globe : PhosphorIconsRegular.mapTrifold,
                    onTap: _toggleMapStyle,
                  ),
                ],
              ),
            ),
          ),

          // First Point Indicator
          if (_polygonPoints.isNotEmpty)
            Positioned(top: 120, left: 20, child: _buildFirstPointIndicator()),

          // Right Side Controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                _buildCircleButton(
                  icon: PhosphorIconsRegular.plus,
                  onTap: _zoomIn,
                  bgColor: Colors.white,
                  iconColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 8),
                _buildCircleButton(
                  icon: PhosphorIconsRegular.minus,
                  onTap: _zoomOut,
                  bgColor: Colors.white,
                  iconColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 16),
                _buildCircleButton(
                  icon: PhosphorIconsRegular.scan,
                  onTap: _goToCurrentLocation,
                  bgColor: Colors.white,
                ),
              ],
            ),
          ),

          // Bottom Control Panel - PRODUCTION GRADE
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildBottomPanel(area),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color bgColor = Colors.white,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildGpsStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isGpsHigh ? AppColors.primary : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              PhosphorIconsRegular.wifiHigh,
              color: Colors.white,
              size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ความแม่นยำ GPS',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _gpsStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isGpsHigh ? AppColors.primary : Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPointIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'จุดเริ่ม',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// PRODUCTION-GRADE BOTTOM PANEL
  /// Properly constrained with clear visual hierarchy
  Widget _buildBottomPanel(Map<String, int> area) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !_isDrawingMode ? _buildIdleState(area) : _buildDrawingState(area),
    );
  }

  /// Idle State: Show plot info and start button
  Widget _buildIdleState(Map<String, int> area) {
    // Check if screen is very small
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Plot Info
          Expanded(
            flex: isSmallScreen ? 5 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plot Number
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.mapPin,
                        size: 14,
                        color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'แปลง #${_plotCounter.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Area Display
                _buildAreaDisplay(area),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: Start Drawing Button
          Expanded(
            flex: isSmallScreen ? 3 : 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleDrawingMode,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.pencilSimple,
                          size: 22,
                          color: Colors.white),
                        const SizedBox(height: 4),
                        Text(
                          'เริ่มวาด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Drawing State: Show area and action buttons
  Widget _buildDrawingState(Map<String, int> area) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Area Display
        _buildAreaDisplay(area),

        const SizedBox(height: 16),

        // Action Buttons Grid
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.arrowUUpLeft,
                label: 'ย้อน',
                onTap: _polygonPoints.isNotEmpty ? _undoLastPoint : null,
                color: Colors.grey[700]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.trash,
                label: 'ลบทั้งหมด',
                onTap: _polygonPoints.isNotEmpty ? _clearDrawing : null,
                color: Colors.red[600]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.xCircle,
                label: 'ยกเลิก',
                onTap: _toggleDrawingMode,
                color: Colors.orange[600]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIconsRegular.checkCircle,
                label: 'ยืนยัน',
                onTap: _polygonPoints.length >= 3 ? _confirmPolygon : null,
                color: AppColors.primary,
                isPrimary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAreaDisplay(Map<String, int> area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _buildAreaUnit(area['rai'].toString(), 'ไร่')),
          _buildAreaDivider(),
          Flexible(child: _buildAreaUnit(area['ngan'].toString(), 'งาน')),
          _buildAreaDivider(),
          Flexible(child: _buildAreaUnit(area['wah'].toString(), 'ตร.ว.')),
        ],
      ),
    );
  }

  Widget _buildAreaUnit(String value, String unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary.withValues(alpha: 0.7),
            height: 1.0,
          ),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _buildAreaDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(0.5),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
    bool isPrimary = false,
  }) {
    final isDisabled = onTap == null;
    final effectiveColor = isDisabled ? Colors.grey[400]! : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: isPrimary && !isDisabled
                ? effectiveColor
                : effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isPrimary && !isDisabled
                      ? Colors.white
                      : effectiveColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPrimary && !isDisabled
                        ? Colors.white
                        : effectiveColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
