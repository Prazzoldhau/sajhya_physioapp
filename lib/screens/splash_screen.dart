import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final api = ApiService();
    await api.init();

    // Try loading cached user immediately — no network needed
    final cached = await api.loadCachedUser();

    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (cached != null) {
      // Navigate instantly with cached data, then validate session in background
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userData: cached)),
      );
      // Validate session silently — HomeScreen handles session expiry via _onSessionExpired
      return;
    }

    // No cached user — try live check
    try {
      final result = await api.me();
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userData: result['user'] as Map<String, dynamic>)),
        );
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/icon.png', height: 100),
            const SizedBox(height: 24),
            const Text(
              'Sajhya Physio',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
