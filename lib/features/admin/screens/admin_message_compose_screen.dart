import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/widgets/custom_popup.dart';
import '../../auth/auth_provider.dart';
import '../../../../data/models/user_model.dart'; 

class AdminMessageComposeScreen extends StatefulWidget {
  final String? initialRecipientId;
  const AdminMessageComposeScreen({super.key, this.initialRecipientId});

  @override
  State<AdminMessageComposeScreen> createState() => _AdminMessageComposeScreenState();
}

class _AdminMessageComposeScreenState extends State<AdminMessageComposeScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSending = false;
  File? _selectedImage;
  
  List<dynamic> _admins = [];
  String? _selectedRecipientId;
  bool _isSuperAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _selectedRecipientId = widget.initialRecipientId;
    _loadRecipients();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      _isSuperAdmin = user?.role == UserRole.superAdmin;
      
      List<dynamic> admins = [];
      if (_isSuperAdmin) {
        admins = await context.read<SuperAdminService>().getAdminList();
      } else {
         try {
           admins = await context.read<AdminService>().getSuperAdmins();
         } catch (e) {
           admins = [];
         }
      }

      if (!mounted) return;
      setState(() {
        _admins = admins;
        _isLoading = false;
        
        if (_selectedRecipientId != null) {
           final exists = _admins.any((a) => a['id'] == _selectedRecipientId);
           if (!exists) _selectedRecipientId = null;
        }
        
        if (_selectedRecipientId == null) {
           if (!_isSuperAdmin && _admins.isNotEmpty) {
             _selectedRecipientId = _admins.first['id'];
           } else if (_admins.length == 1) {
             _selectedRecipientId = _admins.first['id'];
           }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionService.requestPhotosPermission(context);
    if (!hasPermission) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedRecipientId == null) {
      CustomPopup.showError(context, message: 'กรุณาเลือกผู้รับ');
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      CustomPopup.showError(context, message: 'กรุณาระบุหัวข้อเรื่อง');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
       CustomPopup.showError(context, message: 'กรุณาระบุรายละเอียดข้อความ');
       return;
    }

    setState(() => _isSending = true);

    try {
      String finalMessage = _messageController.text.trim();
      
      if (_selectedImage != null) {
        String imageUrl;
        if (_isSuperAdmin) {
           imageUrl = await context.read<SuperAdminService>().uploadFile(_selectedImage!);
        } else {
           imageUrl = await context.read<AdminService>().uploadFile(_selectedImage!);
        }
        finalMessage += '\n\n![แนบรูปภาพ]($imageUrl)';
      }

      if (_isSuperAdmin) {
        await context.read<SuperAdminService>().sendMessage(
          recipientId: _selectedRecipientId!,
          subject: _subjectController.text.trim(),
          message: finalMessage,
        );
      } else {
        await context.read<AdminService>().sendMessage(
          recipientId: _selectedRecipientId!,
          subject: _subjectController.text.trim(),
          message: finalMessage,
        );
      }

      if (!mounted) return;
      
      await CustomPopup.showSuccess(
        context, 
        message: 'ส่งข้อความเรียบร้อยแล้ว',
        onConfirm: () {}
      );
      
      context.pop(true);
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      CustomPopup.showError(context, message: 'ส่งไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isSuperAdmin)
          Container(
             decoration: const BoxDecoration(
               gradient: LuxuryTheme.backgroundGradient,
             ),
          )
        else
          Container(color: const Color(0xFFF5F7FA)),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('เขียนข้อความใหม่', 
              style: _isSuperAdmin 
                  ? GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)
                  : GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.black)
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _isSuperAdmin 
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxuryTheme.glassBorder),
                  ),
                  child: IconButton(
                    icon: const HeroIcon(HeroIcons.xMark, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                )
              : IconButton(
                  icon: const HeroIcon(HeroIcons.xMark, color: Colors.black),
                  onPressed: () => context.pop(),
                ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSuperAdmin) ...[
                  _buildSectionLabel('ถึง (ผู้รับ)'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.glassSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LuxuryTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRecipientId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E2A4A),
                        hint: Text('แตะเพื่อเลือกผู้รับ', style: GoogleFonts.outfit(color: LuxuryTheme.textSecondary)),
                        icon: const HeroIcon(HeroIcons.chevronDown, size: 24, color: LuxuryTheme.cyanNeon),
                        items: _admins.map<DropdownMenuItem<String>>((admin) {
                          final firstName = admin['firstName']?.toString() ?? '';
                          final lastName = admin['lastName']?.toString() ?? '';
                          final role = admin['role']?.toString() ?? '';
                          
                          return DropdownMenuItem(
                            value: admin['id']?.toString(),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: LuxuryTheme.purpleNeon.withOpacity(0.1),
                                  child: Text(
                                    firstName.isNotEmpty ? firstName[0] : '?',
                                    style: GoogleFonts.outfit(fontSize: 12, color: LuxuryTheme.purpleNeon, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$firstName $lastName',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (val) => setState(() => _selectedRecipientId = val),
                      ),
                    ),
                  ),
                ] else ...[
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: AppColors.secondary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                     ),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: const BoxDecoration(
                             color: AppColors.secondary,
                             shape: BoxShape.circle,
                           ),
                           child: const HeroIcon(HeroIcons.shieldCheck, color: Colors.white, size: 24),
                         ),
                         const SizedBox(width: 16),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'ติดต่อผู้ดูแลระบบสูงสุด',
                               style: GoogleFonts.prompt(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.secondary,
                               ),
                             ),
                             Text(
                               'ข้อความจะถูกส่งไปยังทีมงานส่วนกลาง',
                               style: GoogleFonts.prompt(
                                 fontSize: 12,
                                 color: Colors.grey[600],
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
                
                const SizedBox(height: 24),
                
                _buildSectionLabel('หัวข้อเรื่อง'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isSuperAdmin ? const Color(0xFF1E2A4A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: _isSuperAdmin ? Border.all(color: LuxuryTheme.glassBorder) : null,
                    boxShadow: _isSuperAdmin ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _subjectController,
                    cursorColor: _isSuperAdmin ? LuxuryTheme.cyanNeon : null,
                    style: _isSuperAdmin 
                        ? GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)
                        : GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'ระบุหัวข้อเรื่อง...',
                      hintStyle: _isSuperAdmin 
                          ? GoogleFonts.outfit(color: LuxuryTheme.textDisabled)
                          : GoogleFonts.prompt(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      filled: _isSuperAdmin,
                      fillColor: _isSuperAdmin ? Colors.transparent : null,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                _buildSectionLabel('รายละเอียด'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isSuperAdmin ? const Color(0xFF1E2A4A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: _isSuperAdmin ? Border.all(color: LuxuryTheme.glassBorder) : null,
                    boxShadow: _isSuperAdmin ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 8,
                    cursorColor: _isSuperAdmin ? LuxuryTheme.cyanNeon : null,
                    style: _isSuperAdmin 
                        ? GoogleFonts.outfit(fontSize: 16, color: Colors.white)
                        : GoogleFonts.prompt(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความของคุณที่นี่...',
                      hintStyle: _isSuperAdmin
                          ? GoogleFonts.outfit(color: LuxuryTheme.textDisabled)
                          : GoogleFonts.prompt(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(20),
                      border: InputBorder.none,
                      filled: _isSuperAdmin,
                      fillColor: _isSuperAdmin ? Colors.transparent : null,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (_selectedImage != null)
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: _isSuperAdmin ? Border.all(color: LuxuryTheme.glassBorder) : null,
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.black.withOpacity(0.6),
                               shape: BoxShape.circle,
                             ),
                             child: const HeroIcon(HeroIcons.xMark, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                 SizedBox(
                   width: double.infinity,
                   child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.primary.withOpacity(0.5), 
                          width: 1.5
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: HeroIcon(HeroIcons.photo, color: _isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.primary),
                      label: Text(
                        _selectedImage == null ? 'แนบรูปภาพ' : 'เปลี่ยนรูปภาพ',
                        style: _isSuperAdmin
                            ? GoogleFonts.outfit(color: LuxuryTheme.cyanNeon, fontWeight: FontWeight.bold, fontSize: 16)
                            : GoogleFonts.prompt(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                 ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: _isSuperAdmin ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ) : null,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSuperAdmin ? LuxuryTheme.purpleNeon : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isSuperAdmin ? 0 : 8,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HeroIcon(HeroIcons.paperAirplane, color: Colors.white, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'ส่งข้อความ',
                                  style: _isSuperAdmin
                                    ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                                    : GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: _isSuperAdmin
          ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
          : GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2D3748)),
    );
  }
}
