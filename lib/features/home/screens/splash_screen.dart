import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Simulate splash delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = await authProvider.loadUser();

      if (mounted) {
        if (isAuthenticated) {
          // Redirect based on role
          // Redirect based on role
          final user = authProvider.user;
          if (user != null) {
            if (user.role == UserRole.superAdmin) {
              context.go('/super-admin/dashboard');
            } else if (user.role == UserRole.admin) {
              context.go('/admin/dashboard');
            } else {
              context.go('/dashboard');
            }
          }
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 140, // Increased size slightly since padding is gone
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Taptom GAP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
