import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coming_soon_view.dart';

/// Marketplace tab, named "Shop" in the UI.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: const ComingSoonView(
        icon: Icons.storefront_outlined,
        title: 'Shop',
        message: 'Browse and order physio equipment and supplies.',
        color: AppColors.accentTeal,
      ),
    );
  }
}
