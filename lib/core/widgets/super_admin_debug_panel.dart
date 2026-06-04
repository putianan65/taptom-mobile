import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/models/user_model.dart';

/// Debug Panel สำหรับตรวจสอบ Super Admin role
/// แสดงเฉพาะตอน Development (kDebugMode)
class SuperAdminDebugPanel extends StatelessWidget {
  const SuperAdminDebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    
    final user = context.watch<AuthProvider>().user;
    final isCorrectRole = user?.role == UserRole.superAdmin;
    
    return Positioned(
      top: 60,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrectRole ? Colors.greenAccent : Colors.redAccent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCorrectRole ? Colors.greenAccent : Colors.redAccent)
                    .withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCorrectRole ? Icons.check_circle : Icons.error,
                    color: isCorrectRole ? Colors.greenAccent : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '🔍 DEBUG MODE',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white30, height: 16, thickness: 0.5),
              
              _buildRow(
                'Role:', 
                user?.role.name.toUpperCase() ?? 'NULL',
                isCorrectRole ? Colors.greenAccent : Colors.redAccent,
              ),
              _buildRow(
                'Expected:',
                'SUPER_ADMIN',
                Colors.white70,
              ),
              const SizedBox(height: 4),
              _buildRow(
                'Name:',
                '${user?.firstName ?? '-'} ${user?.lastName ?? ''}',
                Colors.cyanAccent,
              ),
              _buildRow(
                'Phone:',
                user?.phone ?? 'NULL',
                Colors.cyanAccent,
              ),
              
              if (!isCorrectRole) ...[
                const Divider(color: Colors.white30, height: 16, thickness: 0.5),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚠️ You logged in as\n${user?.role.name.toUpperCase() ?? 'UNKNOWN'}\nnot SUPER_ADMIN!',
                    style: GoogleFonts.prompt(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.prompt(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.prompt(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
