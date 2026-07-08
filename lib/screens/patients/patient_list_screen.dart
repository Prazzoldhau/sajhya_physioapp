import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/patient_card.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool embedded;

  const PatientListScreen({super.key, this.embedded = false});

  @override
  PatientListScreenState createState() => PatientListScreenState();
}

class PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload({String? q}) async {
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

  void openSearch() {
    showSearch<String>(
      context: context,
      delegate: _PatientSearchDelegate(onSearch: (q) => reload(q: q)),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No patients yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap + Add Patient to get started', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _patients.length,
        itemBuilder: (_, i) => PatientCard(
          patient: _patients[i],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: _patients[i])),
            );
            reload();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildContent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: openSearch),
        ],
      ),
      body: _buildContent(),
    );
  }
}

class _PatientSearchDelegate extends SearchDelegate<String> {
  final Future<void> Function(String? q) onSearch;

  _PatientSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query.isEmpty ? null : query);
    close(context, query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox();
}
