import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../features/auth/models/location_models.dart';
import '../constants/thai_locations.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all regions from API (with local fallback)
  Future<List<String>> getRegions() async {
    try {
      final response = await _apiClient.get('/locations/regions');

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      final regions = (data as List).map((e) => e.toString()).toList();

      if (regions.isNotEmpty) return regions;
    } catch (e) {
      // Fallback to local data
    }
    return List<String>.from(ThaiLocationData.regions);
  }

  /// Get all provinces (with local fallback)
  Future<List<Province>> getProvinces({String? region}) async {
    try {
      final response = await _apiClient.get(
        '/locations/provinces',
        queryParameters: region != null ? {'region': region} : null,
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      final results = (data as List).map((json) {
        // 🛠️ Patch: Fix encoding issues using local data fallback
        final code = json['code'].toString();

        if (code.isNotEmpty) {
          final localMatch = ThaiLocationData.provinces.firstWhere(
            (p) => p['code'] == code,
            orElse: () => {},
          );

          if (localMatch.isNotEmpty) {
            json['nameTh'] = localMatch['nameTh'];
          }
        }

        return Province.fromJson(json);
      }).toList();

      // ✅ If API returned data, use it
      if (results.isNotEmpty) return results;
    } catch (e) {
      // Fallback to local data on error
    }

    // ✅ Fallback: use local data
    return _getLocalProvinces(region: region);
  }

  /// Get districts by province code
  Future<List<District>> getDistricts(String provinceCode) async {
    try {
      final response = await _apiClient.get(
        '/locations/districts',
        queryParameters: {'provinceCode': provinceCode},
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return (data as List).map((json) => District.fromJson(json)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลอำเภอได้: $e');
    }
  }

  /// Get subdistricts by district code
  Future<List<Subdistrict>> getSubdistricts(String districtCode) async {
    try {
      final response = await _apiClient.get(
        '/locations/subdistricts',
        queryParameters: {'districtCode': districtCode},
      );

      final data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return (data as List).map((json) => Subdistrict.fromJson(json)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลตำบลได้: $e');
    }
  }

  /// Local fallback for provinces
  List<Province> _getLocalProvinces({String? region}) {
    var source = ThaiLocationData.provinces;
    if (region != null) {
      source = source.where((p) => p['region'] == region).toList();
    }
    return source
        .map((p) => Province(
              id: p['id'] as int,
              code: p['code'] as String,
              nameTh: p['nameTh'] as String,
              nameEn: p['nameEn'] as String?,
              region: p['region'] as String?,
            ))
        .toList();
  }
}
