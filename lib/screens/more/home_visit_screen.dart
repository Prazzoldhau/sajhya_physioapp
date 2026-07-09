import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coming_soon_view.dart';

class HomeVisitScreen extends StatelessWidget {
  const HomeVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Visit')),
      body: const ComingSoonView(
        icon: Icons.home_work_outlined,
        title: 'Home Visit',
        message: 'Schedule and track physio visits at patients\' homes.',
        color: AppColors.accentOrange,
      ),
    );
  }
}
