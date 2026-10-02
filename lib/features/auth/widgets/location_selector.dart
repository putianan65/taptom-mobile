import 'package:flutter/material.dart';

import '../../../core/constants/thai_locations.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/services/location_service.dart';
import '../../auth/models/location_models.dart';

/// Cascading location selector widget
/// Provides Region → Province → District → Subdistrict selection
class LocationSelector extends StatefulWidget {
  final String? initialRegion;
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialSubdistrict;
  final Function(
    String region,
    String? province,
    String? district,
    String? subdistrict,
  )
  onChanged;
  final bool requireFullAddress;

  const LocationSelector({
    super.key,
    this.initialRegion,
    this.initialProvince,
    this.initialDistrict,
    this.initialSubdistrict,
    required this.onChanged,
    this.requireFullAddress = false,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final LocationService _locationService = LocationService();

  String? _selectedRegion;
  String? _selectedProvince; // Stores province name
  String? _selectedDistrict; // Stores district name
  String? _selectedSubdistrict; // Stores subdistrict name

  String? _selectedProvinceCode;
  String? _selectedDistrictCode;

  List<String> _regions = [];
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Subdistrict> _subdistricts = [];

  bool _isLoadingRegions = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingSubdistricts = false;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedProvince = widget.initialProvince;
    _selectedDistrict = widget.initialDistrict;
    _selectedSubdistrict = widget.initialSubdistrict;

    _fetchRegions();

    if (_selectedRegion != null) {
      _fetchProvinces(_selectedRegion!);
    }
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regions = await _locationService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() {
        _regions = List<String>.from(ThaiLocationData.regions);
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _fetchProvinces(String region) async {
    setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await _locationService.getProvinces(region: region);
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;

        // If we have an initial province, find its code to fetch districts
        if (_selectedProvince != null) {
          final p = provinces.firstWhere(
            (p) => p.nameTh == _selectedProvince,
            orElse: () => Province(id: 0, code: '', nameTh: ''),
          );
          if (p.code.isNotEmpty) {
            _selectedProvinceCode = p.code;
            _fetchDistricts(p.code);
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _fetchDistricts(String provinceCode) async {
    setState(() => _isLoadingDistricts = true);
    try {
      final districts = await _locationService.getDistricts(provinceCode);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;

        // If we have an initial district, find its code to fetch subdistricts
        if (_selectedDistrict != null) {
          final d = districts.firstWhere(
            (d) => d.nameTh == _selectedDistrict,
            orElse: () =>
                District(id: 0, code: '', nameTh: '', provinceCode: ''),
          );
          if (d.code.isNotEmpty) {
            _selectedDistrictCode = d.code;
            _fetchSubdistricts(d.code);
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _fetchSubdistricts(String districtCode) async {
    setState(() => _isLoadingSubdistricts = true);
    try {
      final subdistricts = await _locationService.getSubdistricts(districtCode);
      setState(() {
        _subdistricts = subdistricts;
        _isLoadingSubdistricts = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubdistricts = false);
    }
  }

  void _onRegionChanged(String? value) {
    if (value == _selectedRegion) return;

    setState(() {
      _selectedRegion = value;
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedSubdistrict = null;
      _selectedProvinceCode = null;
      _selectedDistrictCode = null;
      _provinces = [];
      _districts = [];
      _subdistricts = [];
    });

    if (value != null) {
      _fetchProvinces(value);
    }
    _notifyChange();
  }

  void _onProvinceChanged(String? name) {
    if (name == _selectedProvince) return;

    // Find selected province object
    final province = _provinces.firstWhere(
      (p) => p.nameTh == name,
      orElse: () => Province(id: 0, code: '', nameTh: ''),
    );

    setState(() {
      _selectedProvince = name;
      _selectedProvinceCode = province.code.isEmpty ? null : province.code;
      _selectedDistrict = null;
      _selectedSubdistrict = null;
      _selectedDistrictCode = null;
      _districts = [];
      _subdistricts = [];
    });

    if (_selectedProvinceCode != null) {
      _fetchDistricts(_selectedProvinceCode!);
    }
    _notifyChange();
  }

  void _onDistrictChanged(String? name) {
    if (name == _selectedDistrict) return;

    final district = _districts.firstWhere(
      (d) => d.nameTh == name,
      orElse: () => District(id: 0, code: '', nameTh: '', provinceCode: ''),
    );

    setState(() {
      _selectedDistrict = name;
      _selectedDistrictCode = district.code.isEmpty ? null : district.code;
      _selectedSubdistrict = null;
      _subdistricts = [];
    });

    if (_selectedDistrictCode != null) {
      _fetchSubdistricts(_selectedDistrictCode!);
    }
    _notifyChange();
  }

  void _onSubdistrictChanged(String? name) {
    setState(() {
      _selectedSubdistrict = name;
    });
    _notifyChange();
  }

  void _notifyChange() {
    if (_selectedRegion != null) {
      widget.onChanged(
        _selectedRegion!,
        _selectedProvince,
        _selectedDistrict,
        _selectedSubdistrict,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDistrict = _districts.isNotEmpty || _selectedProvince != null;
    final showSubdistrict = _subdistricts.isNotEmpty || _selectedDistrict != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          label: 'ภูมิภาค',
          value: _selectedRegion,
          items: _regions,
          onChanged: _onRegionChanged,
          required: true,
          enabled: !_isLoadingRegions && _regions.isNotEmpty,
          loading: _isLoadingRegions,
        ),
        const SizedBox(height: Space.lg),
        _dropdown(
          label: 'จังหวัด',
          value: _selectedProvince,
          items: _provinces.map((p) => p.nameTh).toList(),
          onChanged: _onProvinceChanged,
          enabled: _selectedRegion != null && !_isLoadingProvinces,
          required: widget.requireFullAddress,
          loading: _isLoadingProvinces,
          hint: _selectedRegion == null ? 'เลือกภูมิภาคก่อน' : null,
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.standard,
          child: !showDistrict
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: Space.lg),
                  child: _dropdown(
                    label: 'อำเภอ / เขต',
                    value: _selectedDistrict,
                    items: _districts.map((d) => d.nameTh).toList(),
                    onChanged: _onDistrictChanged,
                    enabled: _selectedProvince != null &&
                        !_isLoadingDistricts &&
                        _districts.isNotEmpty,
                    required: widget.requireFullAddress,
                    loading: _isLoadingDistricts,
                    hint: _districts.isEmpty && !_isLoadingDistricts
                        ? 'ไม่พบข้อมูลอำเภอ'
                        : null,
                  ),
                ),
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.standard,
          child: !showSubdistrict
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: Space.lg),
                  child: _dropdown(
                    label: 'ตำบล / แขวง',
                    value: _selectedSubdistrict,
                    items: _subdistricts.map((s) => s.nameTh).toList(),
                    onChanged: _onSubdistrictChanged,
                    enabled: _selectedDistrict != null &&
                        !_isLoadingSubdistricts &&
                        _subdistricts.isNotEmpty,
                    required: widget.requireFullAddress,
                    loading: _isLoadingSubdistricts,
                    hint: _subdistricts.isEmpty && !_isLoadingSubdistricts
                        ? 'ไม่พบข้อมูลตำบล'
                        : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
    bool required = false,
    bool loading = false,
    String? hint,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label, required: required),
        DropdownButtonFormField<String>(
          // Re-key on upstream changes so cascading resets are reflected.
          key: ValueKey('$label|$value|${items.length}|$enabled'),
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          menuMaxHeight: 360,
          borderRadius: Radii.control,
          dropdownColor: p.surface,
          decoration: InputDecoration(
            hintText: loading ? 'กำลังโหลด...' : (hint ?? 'เลือก$label'),
          ),
          style: context.text.bodyLarge,
          icon: loading
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.brand),
                )
              : Icon(AppIcons.chevronDown, size: 18, color: p.inkSubtle),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: enabled ? onChanged : null,
          validator: required ? (v) => v == null ? 'กรุณาเลือก$label' : null : null,
        ),
      ],
    );
  }
}
