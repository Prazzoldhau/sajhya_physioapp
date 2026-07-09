import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coming_soon_view.dart';

/// IP (in-patient) request tab.
class IpRequestScreen extends StatelessWidget {
  const IpRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IP Request')),
      body: const ComingSoonView(
        icon: Icons.assignment_add,
        title: 'IP Request',
        message: 'Submit and track in-patient physio requests.',
        color: AppColors.accentIndigo,
      ),
    );
  }
}
