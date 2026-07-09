import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder body for a feature screen that doesn't have a backend yet.
/// Reused by every "in progress" destination so they read as intentional
/// previews rather than broken pages, and can be swapped for real content
/// later without touching the surrounding Scaffold/AppBar.
class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const ComingSoonView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.65)],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Icon(icon, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Coming soon', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
