import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/env.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../data/models/plot_model.dart';
import '../../../../core/widgets/nature_background.dart';

class PlotEditorScreenMapLibre extends StatefulWidget {
  final PlotModel plot;

  const PlotEditorScreenMapLibre({super.key, required this.plot});

  @override
  State<PlotEditorScreenMapLibre> createState() =>
      _PlotEditorScreenMapLibreState();
}

class _PlotEditorScreenMapLibreState extends State<PlotEditorScreenMapLibre> {
  MaplibreMapController? _mapController;
  List<LatLng> polygonPoints = [];
  bool isLoading = false;
  
  // Style URL
  String get _styleUrl =>
      'https://api.maptiler.com/maps/satellite/style.json?key=${Env.mapTilerApiKey}';

  @override
  void initState() {
    super.initState();
    _loadExistingGeometry();
  }

  void _loadExistingGeometry() {
    if (widget.plot.geometry.isNotEmpty &&
        widget.plot.geometry['coordinates'] != null) {
      try {
        final coords = widget.plot.geometry['coordinates'][0] as List;
        polygonPoints = coords.map<LatLng>((c) {
          final point = c as List;
          return LatLng(point[1].toDouble(), point[0].toDouble());
        }).toList();

        if (polygonPoints.length > 1 &&
            polygonPoints.first.latitude == polygonPoints.last.latitude &&
            polygonPoints.first.longitude == polygonPoints.last.longitude) {
          polygonPoints.removeLast();
        }
      } catch (e) {
        debugPrint('Error parsing existing geometry: $e');
      }
    }
  }

  Map<String, dynamic> _buildGeoJSON() {
    final points = List<LatLng>.from(polygonPoints);
    if (points.isNotEmpty) {
       final first = points.first;
       final last = points.last;
       if (first.latitude != last.latitude || first.longitude != last.longitude) {
         points.add(first);
       }
    }

    return {
      'type': 'Polygon',
      'coordinates': [
        points.map((p) => [p.longitude, p.latitude]).toList()
      ]
    };
  }

  Future<void> _saveChanges() async {
    if (polygonPoints.length < 3) {
      _showError('ต้องมีอย่างน้อย 3 จุด');
      return;
    }

    setState(() => isLoading = true);

    try {
      final geometry = _buildGeoJSON();
      final updated = await context.read<PlotService>().updatePlotGeometry(
            plotId: widget.plot.id!,
            geometry: geometry,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('บันทึกสำเร็จ', style: GoogleFonts.prompt()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.prompt()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }
  
  void _onStyleLoaded() {
    _updatePolygonLayer();
  }

  void _onMapClick(Point<double> point, LatLng latLng) {
    if (isLoading) return;
    setState(() {
      polygonPoints.add(latLng);
    });
    _updatePolygonLayer();
  }
  
  void _undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
      });
      _updatePolygonLayer();
    }
  }
  
  void _clearAll() {
    setState(() {
      polygonPoints.clear();
    });
    _updatePolygonLayer();
  }

  Future<void> _updatePolygonLayer() async {
    if (_mapController == null) return;
    
    await _mapController!.clearFills();
    await _mapController!.clearCircles();

    if (polygonPoints.isEmpty) return;

    if (polygonPoints.length >= 3) {
      final displayPoints = List<LatLng>.from(polygonPoints);
      if (displayPoints.first != displayPoints.last) {
         displayPoints.add(displayPoints.first);
      }
      
      await _mapController!.addFill(
        FillOptions(
          geometry: [displayPoints],
          fillColor: AppColors.primary.toHexStringRGB(),
          fillOpacity: 0.35,
          fillOutlineColor: AppColors.primary.toHexStringRGB(),
        ),
      );
    }
    
    for (var point in polygonPoints) {
       await _mapController!.addCircle(
         CircleOptions(
           geometry: point,
           circleColor: '#FFFFFF',
           circleRadius: 6,
           circleStrokeWidth: 2,
           circleStrokeColor: AppColors.primary.toHexStringRGB(),
         )
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full Screen Map
          MaplibreMap(
            styleString: _styleUrl,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapClick,
            initialCameraPosition: CameraPosition(
              target: polygonPoints.isNotEmpty 
                  ? polygonPoints.first 
                  : const LatLng(13.7, 100.5),
              zoom: polygonPoints.isNotEmpty ? 16 : 5,
            ),
            myLocationEnabled: true,
            trackCameraPosition: true,
          ),

          // 2. Guide Overlay
          Positioned(
            top: 120, 
            left: 0, 
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'แตะบนแผนที่เพื่อเพิ่มจุด',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // 3. Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const HeroIcon(HeroIcons.arrowLeft, color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'แก้ไขแปลง',
                            style: GoogleFonts.prompt(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.plot.name,
                            style: GoogleFonts.prompt(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating Tools (Right Side)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolButton(
                  icon: HeroIcons.arrowUturnLeft,
                  onTap: polygonPoints.isEmpty ? null : _undoLastPoint,
                  tooltip: 'ย้อนกลับ',
                ),
                const SizedBox(height: 12),
                _buildToolButton(
                  icon: HeroIcons.trash,
                  onTap: polygonPoints.isEmpty ? null : _clearAll,
                  color: Colors.red,
                  tooltip: 'ล้างจุด',
                ),
                const SizedBox(height: 12),
                _buildToolButton(
                  icon: HeroIcons.informationCircle,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('วิธีใช้งาน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        content: Text(
                          '1. แตะบนแผนที่เพื่อปักหมุดมุมแปลง\n2. ปักหมุดให้ครบ 3 จุดขึ้นไป\n3. กดปุ่มบันทึกด้านล่าง',
                          style: GoogleFonts.prompt(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('ตกลง', style: GoogleFonts.prompt()),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'ช่วยเหลือ',
                ),
              ],
            ),
          ),
          ),

          // 5. Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GoogleFonts.prompt(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: polygonPoints.length >= 3 ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade200,
                        ),
                        child: Text(
                          'บันทึกพิกัดแปลง',
                          style: GoogleFonts.prompt(
                            color: polygonPoints.length >= 3 ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required HeroIcons icon,
    VoidCallback? onTap,
    Color color = AppColors.primary,
    required String tooltip,
  }) {
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: HeroIcon(
            icon,
            color: isEnabled ? color : Colors.grey.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }
}

extension AlignExtension on Positioned {
  Positioned copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    return Positioned(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      width: width ?? this.width,
      height: height ?? this.height,
      child: child,
    );
  }
}

// Helper for center Y alignment in Stack
extension StackAlign on Positioned {
  static Positioned centerY({
    double? left,
    double? right,
    required Widget child,
  }) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: left,
      right: right,
      child: Center(child: child),
    );
  }
}