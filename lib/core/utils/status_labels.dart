import '../../data/models/user_model.dart';
import '../design/palette.dart';

/// Human labels and tones for statuses that come back from the API, so every
/// screen describes the same state with the same words and colour.
abstract final class StatusLabels {
  static (String, Tone) plot(String? status) => switch (status?.toUpperCase()) {
        'APPROVED' => ('อนุมัติแล้ว', Tone.success),
        'PENDING' => ('รอตรวจสอบ', Tone.warning),
        'REJECTED' => ('ไม่ผ่านการตรวจ', Tone.danger),
        'DRAFT' => ('ฉบับร่าง', Tone.neutral),
        _ => ('ยังไม่ส่งตรวจ', Tone.neutral),
      };

  static (String, Tone) membership(MembershipStatus status) => switch (status) {
        MembershipStatus.approved => ('สมาชิก', Tone.success),
        MembershipStatus.pending => ('รออนุมัติ', Tone.warning),
        MembershipStatus.rejected => ('ไม่อนุมัติ', Tone.danger),
        MembershipStatus.none => ('ยังไม่สังกัด', Tone.neutral),
      };

  static (String, Tone) membershipString(String? status) =>
      switch (status?.toUpperCase()) {
        'APPROVED' => ('สมาชิก', Tone.success),
        'PENDING' => ('รออนุมัติ', Tone.warning),
        'REJECTED' => ('ไม่อนุมัติ', Tone.danger),
        _ => ('ยังไม่สังกัด', Tone.neutral),
      };

  static String role(UserRole role) => switch (role) {
        UserRole.farmer => 'เกษตรกร',
        UserRole.admin => 'เจ้าหน้าที่',
        UserRole.superAdmin => 'ผู้ดูแลระบบ',
      };

  static String roleString(String? role) => switch (role?.toUpperCase()) {
        'ADMIN' => 'เจ้าหน้าที่',
        'SUPER_ADMIN' => 'ผู้ดูแลระบบ',
        _ => 'เกษตรกร',
      };

  static (String, Tone) ticket(String? status) => switch (status?.toUpperCase()) {
        'OPEN' => ('เปิดอยู่', Tone.info),
        'IN_PROGRESS' => ('กำลังดำเนินการ', Tone.warning),
        'RESOLVED' => ('แก้ไขแล้ว', Tone.success),
        'CLOSED' => ('ปิดแล้ว', Tone.neutral),
        _ => ('ไม่ทราบสถานะ', Tone.neutral),
      };
}
