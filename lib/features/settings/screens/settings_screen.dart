import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pdpa_content.dart';
import '../settings_provider.dart';
import '../../../../core/services/feedback_service.dart';
import 'content_display_screen.dart';
import '../../../../core/services/cache_service.dart';

/// Production-grade Settings Screen
/// Improvements:
/// - Better error handling for URL launches
/// - Confirmation dialogs for destructive actions
/// - Loading states
/// - Accessibility improvements
/// - Better visual feedback
class SettingsScreen extends StatefulWidget {
  final String version;
  const SettingsScreen({super.key, this.version = '1.0.0'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isClearingCache = false;

  // ==================== DIALOGS ====================

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                PhosphorIconsRegular.warning,
                color: AppColors.warning,
                size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ล้างแคช',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการล้างข้อมูลแคชของแอปหรือไม่?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.info,
                    color: AppColors.info,
                    size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การล้างแคชจะไม่ลบข้อมูลสำคัญของคุณ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isClearingCache
                ? null
                : () => Navigator.of(dialogContext).pop(),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _isClearingCache
                ? null
                : () async {
                    setState(() => _isClearingCache = true);

                    // Real cache clearing
                    await CacheService().clearAllCache();
                    // Optional: artificial delay to let user see the spinner
                    await Future.delayed(const Duration(milliseconds: 500));

                    if (!mounted) return;

                    setState(() => _isClearingCache = false);
                    Navigator.of(dialogContext).pop();

                    _showSuccessSnackBar('ล้างแคชเรียบร้อยแล้ว');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isClearingCache
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'ล้างแคช',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    int selectedRating = 5;
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'ให้คะแนนแอป',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => selectedRating = index + 1),
                      icon: Icon(
                        index < selectedRating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        color: AppColors.warning,
                        size: 32,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    hintText: 'ข้อเสนอแนะเพิ่มเติม (ไม่บังคับ)',
                    hintStyle: TextStyle(fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text('ยกเลิก', style: const TextStyle()),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await FeedbackService().submitRating(
                            rating: selectedRating,
                            feedback: feedbackController.text.trim(),
                            platform: 'android', // TODO: Get real platform
                            appVersion: widget.version, // Use passed version
                          );
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            _showSuccessSnackBar('ขอบคุณสำหรับคะแนน! ⭐');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackBar('เกิดข้อผิดพลาดในการส่งคะแนน');
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('ส่ง', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== URL LAUNCHER ====================

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('ไม่สามารถเปิดลิงก์ได้');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('ไม่สามารถเปิดลิงก์ได้: ${e.toString()}');
    }
  }

  // ==================== SNACKBARS ====================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.checkCircle,
              color: Colors.white,
              size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              color: Colors.white,
              size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Image
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/ปกกระท่อม.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary,
                        child: const Center(
                          child: Icon(
                            PhosphorIconsRegular.image,
                            color: Colors.white,
                            size: 48),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.textPrimary.withValues(alpha: 0.3),
                          AppColors.textPrimary.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.gear,
                            color: AppColors.textLight,
                            size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ตั้งค่า',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.shadowMedium, blurRadius: 8),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        PhosphorIconsRegular.arrowLeft,
                        color: AppColors.textPrimary,
                        size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ========== การตั้งค่าทั่วไป ==========
                      _buildSectionHeader(
                        'การตั้งค่าทั่วไป',
                        PhosphorIconsRegular.gear,
                      ),
                      const SizedBox(height: 12),

                      _buildSwitchCard(
                        icon: PhosphorIconsRegular.bell,
                        iconColor: AppColors.warning,
                        title: 'การแจ้งเตือน',
                        subtitle: 'รับข่าวสารและอัปเดตสถานะ',
                        value: settings.notificationsEnabled,
                        onChanged: (val) async {
                          final success = await settings.toggleNotifications(val);
                          if (!success && mounted) {
                             _showErrorSnackBar(
                               'กรุณาเปิดสิทธิ์การแจ้งเตือนในตั้งค่าอุปกรณ์',
                            );
                          }
                        },
                      ),

                      _buildActionCard(
                        icon: PhosphorIconsRegular.trash,
                        iconColor: AppColors.error,
                        title: 'ล้างแคช',
                        subtitle: 'ลบข้อมูลชั่วคราวของแอป',
                        onTap: _showClearCacheDialog,
                      ),

                      const SizedBox(height: 24),

                      // ========== ข้อมูลและกฎหมาย ==========
                      _buildSectionHeader(
                        'ข้อมูลและกฎหมาย',
                        PhosphorIconsRegular.fileText,
                      ),
                      const SizedBox(height: 12),

                      _buildActionCard(
                        icon: PhosphorIconsRegular.fileText,
                        iconColor: AppColors.info,
                        title: 'ข้อกำหนดและเงื่อนไข',
                        subtitle: 'อ่านข้อกำหนดการใช้งาน',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContentDisplayScreen(
                                title: 'ข้อกำหนดและเงื่อนไข',
                                content: '''
1. การยอมรับข้อกำหนด
การใช้งานแอปพลิเคชันนี้ ถือว่าท่านยอมรับข้อกำหนดและเงื่อนไขทั้งหมด

2. การใช้งานข้อมูล
ข้อมูลของท่านจะถูกเก็บรักษาเป็นความลับและใช้เพื่อการปรับปรุงบริการ TAPTOM เท่านั้น

3. ลิขสิทธิ์
เนื้อหาและข้อมูลทั้งหมดในแอปพลิเคชันเป็นลิขสิทธิ์ของ TAPTOM Mobile

4. การเปลี่ยนแปลง
เราขอสงวนสิทธิ์ในการแก้ไขข้อกำหนดเหล่านี้โดยไม่ต้องแจ้งให้ทราบล่วงหน้า

5. ความรับผิดชอบ
ผู้ใช้งานมีความรับผิดชอบในการใช้งานแอปพลิเคชันอย่างถูกต้องตามกฎหมาย

6. การสนับสนุน
หากมีข้อสงสัยหรือต้องการความช่วยเหลือ กรุณาติดต่อทีมพัฒนา
                                ''',
                              ),
                            ),
                          );
                        },
                      ),

                      _buildActionCard(
                        icon: PhosphorIconsRegular.shieldCheck,
                        iconColor: AppColors.primary,
                        title: 'นโยบายคุ้มครองข้อมูล (PDPA)',
                        subtitle: 'อ่านนโยบายความเป็นส่วนตัว',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContentDisplayScreen(
                                title: PdpaContent.title,
                                content:
                                    '${PdpaContent.fullContent}\n\n${PdpaContent.references}',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // ========== เกี่ยวกับแอป ==========
                      _buildSectionHeader(
                        'เกี่ยวกับแอป',
                        PhosphorIconsRegular.info,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: PhosphorIconsRegular.deviceMobile,
                        iconColor: AppColors.primary,
                        title: 'TAPTOM',
                        subtitle: 'แอปบันทึกข้อมูล GAP กระท่อม',
                      ),

                      _buildInfoCard(
                        icon: PhosphorIconsRegular.code,
                        iconColor: AppColors.superAdminPrimary,
                        title: 'เวอร์ชัน',
                        subtitle: settings.version.isEmpty
                            ? 'กำลังโหลด...'
                            : settings.version,
                      ),

                      _buildActionCard(
                        icon: PhosphorIconsRegular.star,
                        iconColor: AppColors.warning,
                        title: 'ให้คะแนนแอป',
                        subtitle: 'ช่วยเราปรับปรุงแอปให้ดีขึ้น',
                        onTap: () => _showRatingDialog(context),
                      ),

                      const SizedBox(height: 32),

                      // Footer
                      _buildFooter(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: AppColors.shadowLight,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  PhosphorIconsRegular.caretRight,
                  color: AppColors.textSecondary,
                  size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/Gistnu_new_logo.webp',
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsRegular.image,
                    color: Colors.grey,
                    size: 24),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'พัฒนาโดย GISTNU',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'มหาวิทยาลัยนเรศวร',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
