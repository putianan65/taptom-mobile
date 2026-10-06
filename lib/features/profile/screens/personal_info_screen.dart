import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../auth/widgets/location_selector.dart';

/// Profile editor shared by every role. Phone number and birthday are the
/// sign-in credentials, so they are shown but changed only by staff.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _form = GlobalKey<FormState>();
  late final UserModel? _user = context.read<AuthProvider>().currentUser;
  late final _first = TextEditingController(text: _user?.firstName);
  late final _last = TextEditingController(text: _user?.lastName);
  late final _job = TextEditingController(text: _user?.job);
  late String? _region = _user?.region;
  late String? _province = _user?.province;
  late String? _district = _user?.district;
  late String? _subdistrict = _user?.subdistrict;
  bool _saving = false;
  bool _uploading = false;
  bool _dirty = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _job.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final current = auth.currentUser;
    if (current == null) return;

    setState(() => _saving = true);
    try {
      await auth.updateProfile(
        current.copyWith(
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          job: _job.text.trim().isEmpty ? null : _job.text.trim(),
          region: _region,
          province: _province,
          district: _district,
          subdistrict: _subdistrict,
        ),
      );
      if (!mounted) return;
      AppToast.success(context, 'บันทึกข้อมูลแล้ว');
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    final admin = context.read<AdminService>();
    final current = auth.currentUser;
    if (current == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      // Staff have a dedicated endpoint; members use the generic upload.
      final url = current.isStaff ? await admin.uploadProfilePhoto(file) : await admin.uploadFile(file);
      await auth.updateProfile(current.copyWith(photoUrl: url));
      if (mounted) AppToast.success(context, 'เปลี่ยนรูปโปรไฟล์แล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, 'อัปโหลดรูปไม่สำเร็จ: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String? _required(String? v, String label) => (v ?? '').trim().isEmpty ? 'กรอก$label' : null;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Scaffold();

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await AppDialogs.confirm(
          context,
          title: 'ทิ้งการแก้ไข?',
          message: 'ข้อมูลที่แก้ไขยังไม่ถูกบันทึก',
          confirmLabel: 'ทิ้งการแก้ไข',
          cancelLabel: 'แก้ไขต่อ',
          destructive: true,
        );
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: PageScaffold(
        title: 'ข้อมูลส่วนตัว',
        bottomBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
            child: AppButton(
              label: 'บันทึก',
              expand: true,
              loading: _saving,
              onPressed: _dirty ? _save : null,
            ),
          ),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: ContentWidth(
              maxWidth: Breakpoints.maxForm,
              padding: EdgeInsets.zero,
              child: Form(
                key: _form,
                onChanged: _touch,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InitialsAvatar(name: user.fullName, photoUrl: user.photoUrl, size: 96),
                          if (!kIsWeb)
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: _uploading
                                  ? Container(
                                      width: 36,
                                      height: 36,
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: p.brand),
                                    )
                                  : AppIconButton(
                                      icon: AppIcons.camera,
                                      tooltip: 'เปลี่ยนรูปโปรไฟล์',
                                      size: 36,
                                      background: p.brand,
                                      foreground: p.onBrand,
                                      onPressed: _changePhoto,
                                    ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    Center(
                      child: StatusBadge(label: StatusLabels.role(user.role), tone: Tone.brand, dot: false),
                    ),
                    const SizedBox(height: Space.xxl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'ชื่อ',
                            controller: _first,
                            validator: (v) => _required(v, 'ชื่อ'),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: AppTextField(
                            label: 'นามสกุล',
                            controller: _last,
                            validator: (v) => _required(v, 'นามสกุล'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    AppTextField(
                      label: user.isStaff ? 'ตำแหน่ง' : 'อาชีพ',
                      controller: _job,
                      icon: AppIcons.officer,
                      hint: user.isStaff ? 'เช่น นักวิชาการส่งเสริมการเกษตร' : 'เช่น เกษตรกร',
                    ),
                    const SizedBox(height: Space.xxl),
                    SectionHeader(
                      title: user.isStaff ? 'พื้นที่ประจำ' : 'ที่อยู่',
                      subtitle: user.isStaff ? 'พื้นที่ดูแลกำหนดโดยผู้ดูแลระบบ' : null,
                    ),
                    if (user.isStaff)
                      ListGroup(
                        children: [
                          KeyValueRow(label: 'ภูมิภาค', value: user.region ?? '-'),
                          KeyValueRow(label: 'จังหวัด', value: user.province ?? '-'),
                          KeyValueRow(label: 'อำเภอ', value: user.district ?? '-'),
                          KeyValueRow(label: 'ตำบล', value: user.subdistrict ?? '-'),
                        ],
                      )
                    else
                      LocationSelector(
                        initialRegion: _region,
                        initialProvince: _province,
                        initialDistrict: _district,
                        initialSubdistrict: _subdistrict,
                        onChanged: (region, province, district, sub) {
                          setState(() {
                            _region = region;
                            _province = province;
                            _district = district;
                            _subdistrict = sub;
                          });
                          _touch();
                        },
                      ),
                    const SizedBox(height: Space.xxl),
                    const SectionHeader(title: 'ข้อมูลเข้าสู่ระบบ'),
                    ListGroup(
                      children: [
                        KeyValueRow(label: 'เบอร์โทรศัพท์', value: user.phone, mono: true, icon: AppIcons.phone),
                        KeyValueRow(
                          label: 'วันเกิด',
                          value: user.birthDate == null ? '-' : ThaiDate.long(user.birthDate!),
                          icon: AppIcons.birthday,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'เบอร์โทรและวันเกิดใช้เข้าสู่ระบบ หากต้องการเปลี่ยน ติดต่อเจ้าหน้าที่ในพื้นที่',
                      style: context.text.bodySmall,
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
}
