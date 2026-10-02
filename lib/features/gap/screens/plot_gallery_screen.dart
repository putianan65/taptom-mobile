import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/nature_background.dart';

class PlotGalleryScreen extends StatefulWidget {
  final String plotId;
  final String? plotName;

  const PlotGalleryScreen({
    super.key,
    required this.plotId,
    this.plotName,
    this.isReadOnly = false,
  });

  final bool isReadOnly;

  @override
  State<PlotGalleryScreen> createState() => _PlotGalleryScreenState();
}

class _PlotGalleryScreenState extends State<PlotGalleryScreen> {
  final _plotService = PlotService();
  final _picker = ImagePicker();
  
  bool _isLoading = true;
  bool _isUploading = false;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final plot = await _plotService.getPlot(widget.plotId);
      if (mounted) {
        setState(() {
          _imageUrls = List<String>.from(plot.imageUrls);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('โหลดรูปภาพไม่สำเร็จ: ${e.toString()}');
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);

        // 1. Upload Image
        final File file = File(pickedFile.path);
        final String uploadedUrl = await _plotService.uploadPlotImage(file);

        // 2. Update Plot with new image list
        final List<String> updatedList = [..._imageUrls, uploadedUrl];
        await _plotService.updatePlot(widget.plotId, {'imageUrls': updatedList});

        // 3. Refresh UI
        if (mounted) {
          setState(() {
            _imageUrls = updatedList;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัปโหลดรูปภาพเรียบร้อย', style: const TextStyle()),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError(ErrorUtils.getReadableError(e));
      }
    }
  }
  
  Future<void> _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ลบรูปภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบรูปภาพนี้หรือไม่?', style: const TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUploading = true);
      try {
        final updatedList = List<String>.from(_imageUrls);
        updatedList.removeAt(index);
        
        await _plotService.updatePlot(widget.plotId, {'imageUrls': updatedList});
        
        if (mounted) {
          setState(() {
            _imageUrls = updatedList;
            _isUploading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          _showError('ลบรูปภาพไม่สำเร็จ');
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera, color: AppColors.primary),
              title: Text('ถ่ายรูป', style: const TextStyle()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image, color: AppColors.primary),
              title: Text('เลือดจุดคลังภาพ', style: const TextStyle()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'อัลบั้มภาพแปลง',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: widget.isReadOnly 
            ? null 
            : FloatingActionButton.extended(
                onPressed: _isUploading ? null : _showPickOptions,
                backgroundColor: AppColors.primary,
                icon: _isUploading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(PhosphorIconsRegular.camera, color: Colors.white),
                label: Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.white)),
              ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _imageUrls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.image, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีรูปภาพแปลง',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          Text(
                            'กดปุ่ม "เพิ่มรูปภาพ" เพื่ออัปโหลด',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _imageUrls.length,
                      itemBuilder: (ctx, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(PhosphorIconsRegular.warningCircle, color: Colors.grey)),
                                ),
                              ),
                            ),
                            if (!widget.isReadOnly)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(PhosphorIconsRegular.trash, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
