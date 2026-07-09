import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coming_soon_view.dart';

/// Shows "My Clinics" for solo/clinic-owner accounts, or "Enterprise" for
/// enterprise accounts — driven by the backend's `user_type` field.
class ClinicsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ClinicsScreen({super.key, required this.userData});

  bool get _isEnterprise => (userData['user_type']?.toString().toLowerCase() ?? '').contains('enterprise');

  @override
  Widget build(BuildContext context) {
    final title = _isEnterprise ? 'Enterprise' : 'My Clinics';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonView(
        icon: _isEnterprise ? Icons.apartment_outlined : Icons.local_hospital_outlined,
        title: title,
        message: _isEnterprise
            ? 'Manage branches, staff and enterprise-wide reporting from one place.'
            : 'Manage your clinic locations, staff and settings from one place.',
        color: AppColors.primary,
      ),
    );
  }
}
