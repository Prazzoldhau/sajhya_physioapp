import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'patients/patient_list_screen.dart';
import 'referrals/referral_list_screen.dart';
import 'patients/create_patient_screen.dart';
import 'referrals/create_referral_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _patientKey = GlobalKey<PatientListScreenState>();
  final _referralKey = GlobalKey<ReferralListScreenState>();

  void _switchTab(int index) => setState(() => _tab = index);

  String get _appBarTitle {
    switch (_tab) {
      case 1: return 'Patients';
      case 2: return 'Referrals';
      default: return 'Sajhya Physio';
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          if (_tab == 1)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _patientKey.currentState?.openSearch(),
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Row(
                children: [Icon(Icons.logout, size: 18), SizedBox(width: 8), Text('Sign Out')],
              )),
            ],
            onSelected: (v) { if (v == 'logout') _logout(); },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(
            userData: widget.userData,
            onNavigateToPatients: () => _switchTab(1),
            onNavigateToReferrals: () => _switchTab(2),
          ),
          PatientListScreen(key: _patientKey, embedded: true),
          ReferralListScreen(key: _referralKey, embedded: true),
        ],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send),
            label: 'Referrals',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (_tab == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePatientScreen()),
          );
          if (created == true) _patientKey.currentState?.reload();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
        backgroundColor: AppColors.primary,
      );
    }
    if (_tab == 2) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReferralScreen()),
        ).then((_) => _referralKey.currentState?.reload()),
        icon: const Icon(Icons.send),
        label: const Text('New Referral'),
        backgroundColor: AppColors.secondary,
      );
    }
    return null;
  }
}
