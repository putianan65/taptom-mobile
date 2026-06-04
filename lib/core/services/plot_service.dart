import 'package:dio/dio.dart';
import 'dart:io';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../data/models/plot_model.dart';
import '../../locator.dart';
import 'auth_service.dart';
import 'notification_trigger_service.dart';

class PlotService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PlotModel>> getMyPlots() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.plots);
      // Assuming backend returns List directly or inside 'data'
      final List data = response.data is List
          ? response.data
          : response.data['data'] ?? [];
      return data.map((e) => PlotModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลแปลงได้: $e');
    }
  }

  /// Get Plot Detail by ID
  Future<PlotModel> getPlot(String plotId) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.plots}/$plotId');
      return PlotModel.fromJson(response.data);
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลแปลงได้: $e');
    }
  }

  Future<PlotModel> createPlot(PlotModel plot) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.plots,
        data: plot.toJson(),
      );
      final newPlot = PlotModel.fromJson(response.data);
      
      // ✅ Trigger notification for Admin
      try {
        final triggerService = locator<NotificationTriggerService>();
        final user = await locator<AuthService>().getCurrentUser();
        await triggerService.onPlotCreated(
          plotId: newPlot.id.toString(),
          plotName: newPlot.name,
          userId: user?.id ?? 'UNKNOWN',
          adminIds: [],
        );
      } catch (e) {
        // Silent error
        print('Trigger notification failed: $e');
      }

      return newPlot;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('ข้อมูลแปลงไม่ถูกต้อง ตรวจสอบชื่อแปลงและพิกัด');
      }
      throw Exception('สร้างแปลงไม่สำเร็จ: ${e.message}');
    } catch (e) {
      throw Exception('Error creating plot: $e');
    }
  }

  Future<Map<String, dynamic>> getPlotSummary() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.plotSummary);
      return response.data;
    } catch (e) {
      return {};
    }
  }

  /// Delete a plot by ID
  Future<void> deletePlot(String plotId) async {
    try {
      await _apiClient.delete('${ApiEndpoints.plots}/$plotId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('ไม่พบแปลงนี้');
      }
      throw Exception('ลบแปลงไม่สำเร็จ: ${e.message}');
    }
  }

  /// Update a plot by ID (PATCH request - partial update)
  Future<PlotModel> updatePlot(String plotId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.plots}/$plotId',
        data: data,
      );
      return PlotModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('ไม่พบแปลงนี้');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์แก้ไขแปลงนี้');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('ข้อมูลไม่ถูกต้อง ตรวจสอบข้อมูลที่กรอก');
      }
      throw Exception('แก้ไขแปลงไม่สำเร็จ: ${e.message}');
    }
  }
  /// Update plot geometry (Edit Polygon)
  Future<PlotModel> updatePlotGeometry({
    required String plotId,
    required Map<String, dynamic> geometry,
  }) async {
    // Validation before sending to API
    _validateGeoJSON(geometry);

    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.plots}/$plotId',
        data: {'geometry': geometry},
      );
      return PlotModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('ไม่พบแปลงนี้');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์แก้ไขแปลงนี้');
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'ข้อมูลพิกัดไม่ถูกต้อง';
        throw Exception('แก้ไขแปลงไม่สำเร็จ: $message');
      }
      throw Exception('แก้ไขแปลงไม่สำเร็จ: ${e.message}');
    } catch (e) {
      throw Exception('Error updating plot geometry: $e');
    }
  }

  // Helper for validate
  void _validateGeoJSON(Map<String, dynamic> geometry) {
    if (geometry['type'] != 'Polygon') {
      throw Exception('GeoJSON type must be "Polygon"');
    }

    final coords = geometry['coordinates'];
    if (coords == null || (coords as List).isEmpty) {
      throw Exception('Coordinates cannot be empty');
    }

    final ring = coords[0] as List;
    if (ring.length < 4) {
      throw Exception('Polygon must have at least 3 points (4 with closure)');
    }

    // Check if polygon is closed
    final first = ring.first as List;
    final last = ring.last as List;
    // Check deep equality for coordinates
    if (first[0] != last[0] || first[1] != last[1]) {
      throw Exception('Polygon must be closed (first point == last point)');
    }
  }

  /// Upload Plot Image
  Future<String> uploadPlotImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.upload,
        data: formData,
      );

      // Backend returns { "url": "...", "filename": "..." }
      return response.data['url'];
    } on DioException catch (e) {
      throw Exception('อัพโหลดรูปภาพไม่สำเร็จ: ${e.message}');
    }
  }
}
