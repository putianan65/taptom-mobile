import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/custom_popup.dart';
import '../../../../core/widgets/nature_background.dart';
import '../../../../data/models/user_model.dart';
import '../../map/screens/map_drawing_screen.dart'; // Fixed: Import MapDrawingScreen

// Note: This needs integration with the Map Drawing Logic used in User App.
// For now, we stub the User Selector and then would navigate to Map.
class CreatePlotForUserScreen extends StatefulWidget {
  final UserModel? initialUser;

  const CreatePlotForUserScreen({super.key, this.initialUser});

  @override
  State<CreatePlotForUserScreen> createState() => _CreatePlotForUserScreenState();
}

class _CreatePlotForUserScreenState extends State<CreatePlotForUserScreen> {
  UserModel? _selectedUser;
  bool _isLoadingUser = false;
  List<UserModel> _users = [];
  
  @override
  void initState() {
    super.initState();
    // Note: _selectedUser is set in _loadUsers after users are loaded
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUser = true);
    try {
      final users = await context.read<AdminService>().getUsers(status: 'APPROVED');
      setState(() {
        _users = users;
        _isLoadingUser = false;
        // Find matching user from loaded list by ID (fixes DropdownButton value mismatch)
        if (widget.initialUser != null) {
          _selectedUser = _users.firstWhere(
            (u) => u.id == widget.initialUser!.id,
            orElse: () => widget.initialUser!, // Fallback to original if not found
          );
          // If fallback was used but user not in list, reset to null to avoid error
          if (!_users.any((u) => u.id == _selectedUser?.id)) {
            _selectedUser = null;
          }
        }
      });
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoadingUser = false);
      CustomPopup.showError(context, message: 'ไม่สามารถโหลดรายชื่อสมาชิกได้');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('ลงทะเบียนแปลงใหม่ (ให้เกษตรกร)', style: GoogleFonts.prompt()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'ขั้นตอนที่ 1: ระบุเจ้าของแปลงใหม่',
                      style: GoogleFonts.prompt(
                        fontSize: 18, // Larger
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                     Text(
                      'เลือกเกษตรกรที่ต้องการสร้างแปลงให้',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกษตรกร:',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingUser)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<UserModel>(
                        value: _selectedUser,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่อ หรือ เบอร์โทร',
                          hintStyle: GoogleFonts.prompt(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.search),
                        ),
                        isExpanded: true,
                        items: _users.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text(
                              '${user.fullName} (${user.phone})',
                              style: GoogleFonts.prompt(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedUser = val),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: _selectedUser == null
                      ? Text(
                          'กรุณาเลือกเกษตรกรก่อนเริ่มวาดแปลง',
                          style: GoogleFonts.prompt(color: Colors.grey),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const HeroIcon(
                              HeroIcons.map,
                              size: 64,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to Map Drawing Screen with User Context
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapDrawingScreen(
                                      isAdmin: true,
                                      targetUserId: _selectedUser!.id, // Pass selected user ID
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_location_alt),
                              label: Text('เริ่มวาดแปลง', style: GoogleFonts.prompt()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'กำลังดำเนินการสำหรับ: ${_selectedUser!.fullName}',
                              style: GoogleFonts.prompt(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
