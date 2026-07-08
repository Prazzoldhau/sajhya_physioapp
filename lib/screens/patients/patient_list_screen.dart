import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/patient_card.dart';
import '../login_screen.dart';
import 'patient_detail_screen.dart';
import 'create_patient_screen.dart';
import '../referrals/referral_list_screen.dart';

class PatientListScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PatientListScreen({super.key, required this.userData});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchCtrl = TextEditingController();
  List<Patient> _patients = [];
  bool _loading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? q}) async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService().getPatients(q: q);
      setState(() => _patients = raw.map(Patient.fromJson).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String get _userName =>
      widget.userData['full_name']?.toString().trim().isNotEmpty == true
          ? widget.userData['full_name'] as String
          : widget.userData['username'] as String? ?? 'Physio';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _navIndex == 0
            ? Text('Hello, $_userName 👋', style: const TextStyle(fontSize: 16))
            : const Text('Referrals'),
        actions: [
          if (_navIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(
                context: context,
                delegate: _PatientSearchDelegate(onSearch: _load),
              ),
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (v) { if (v == 'logout') _logout(); },
          ),
        ],
      ),
      body: _navIndex == 0 ? _patientList() : ReferralListScreen(embedded: true),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePatientScreen()),
                );
                if (created == true) _load();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Patient'),
              backgroundColor: AppColors.primary,
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReferralListScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Referral'),
              backgroundColor: AppColors.secondary,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send), label: 'Referrals'),
        ],
      ),
    );
  }

  Widget _patientList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No patients yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _patients.length,
        itemBuilder: (_, i) => PatientCard(
          patient: _patients[i],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDetailScreen(patient: _patients[i]),
              ),
            );
            _load();
          },
        ),
      ),
    );
  }
}

class _PatientSearchDelegate extends SearchDelegate<String> {
  final Future<void> Function({String? q}) onSearch;

  _PatientSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    onSearch(q: query);
    close(context, query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox();
}
