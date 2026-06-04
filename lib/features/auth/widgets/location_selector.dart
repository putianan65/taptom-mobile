import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/thai_locations.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const HeroIcon(
                HeroIcons.mapPin,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'ที่อยู่',
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),

        // Region
        _buildDropdown(
          label: 'ภูมิภาค',
          value: _selectedRegion,
          items: _regions,
          onChanged: _onRegionChanged,
          isRequired: true,
          isEnabled: !_isLoadingRegions && _regions.isNotEmpty,
          hint: _isLoadingRegions ? 'กำลังโหลด...' : null,
        ),
        const SizedBox(height: 12),

        // Province
        _buildDropdown(
          label: 'จังหวัด',
          value: _selectedProvince,
          items: _provinces.map((p) => p.nameTh).toList(),
          onChanged: _onProvinceChanged,
          isEnabled: _selectedRegion != null && !_isLoadingProvinces,
          isRequired: widget.requireFullAddress,
          hint: _isLoadingProvinces ? 'กำลังโหลด...' : null,
        ),
        const SizedBox(height: 12),

        // District
        if (_districts.isNotEmpty || _selectedProvince != null)
          Column(
            children: [
              _buildDropdown(
                label: 'อำเภอ/เขต',
                value: _selectedDistrict,
                items: _districts.map((d) => d.nameTh).toList(),
                onChanged: _onDistrictChanged,
                isEnabled:
                    _selectedProvince != null &&
                    !_isLoadingDistricts &&
                    _districts.isNotEmpty,
                isRequired: widget.requireFullAddress,
                hint: _isLoadingDistricts
                    ? 'กำลังโหลด...'
                    : (_districts.isEmpty && _selectedProvince != null
                          ? 'ไม่มีข้อมูลอำเภอ'
                          : null),
              ),
              const SizedBox(height: 12),
            ],
          ),

        // Subdistrict
        if (_subdistricts.isNotEmpty || _selectedDistrict != null)
          _buildDropdown(
            label: 'ตำบล/แขวง',
            value: _selectedSubdistrict,
            items: _subdistricts.map((s) => s.nameTh).toList(),
            onChanged: _onSubdistrictChanged,
            isEnabled:
                _selectedDistrict != null &&
                !_isLoadingSubdistricts &&
                _subdistricts.isNotEmpty,
            isRequired: widget.requireFullAddress,
            hint: _isLoadingSubdistricts
                ? 'กำลังโหลด...'
                : (_subdistricts.isEmpty && _selectedDistrict != null
                      ? 'ไม่มีข้อมูลตำบล'
                      : null),
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isEnabled = true,
    bool isRequired = false,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
        filled: true,
        fillColor: isEnabled ? AppColors.background : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.prompt(color: Colors.grey[400], fontSize: 13),
      ),
      style: GoogleFonts.prompt(color: AppColors.textMain, fontSize: 14),
      icon: const HeroIcon(
        HeroIcons.chevronDown,
        size: 20,
        color: AppColors.primary,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.prompt()),
            ),
          )
          .toList(),
      onChanged: isEnabled ? onChanged : null,
      validator: isRequired
          ? (val) => val == null ? 'กรุณาเลือก$label' : null
          : null,
    );
  }
}
