import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'clinic_detail_screen.dart';
import 'create_clinic_screen.dart';

/// "My Clinics" — lists the clinics the logged-in user owns, backed by
/// GET /physio-api/clinics/.
class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  List<Map<String, dynamic>>? _clinics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final clinics = await ApiService().getClinics();
      if (mounted) setState(() => _clinics = clinics);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Clinics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateClinicScreen()));
          if (created == true) _load();
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Clinic'),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(builder: (context) {
          if (_error != null) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Could not load clinics.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            );
          }
          if (_clinics == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_clinics!.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No clinics yet. Tap "Add Clinic" to create one.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _clinics!.length,
            itemBuilder: (_, i) {
              final c = _clinics![i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                  ),
                  title: Text(c['clinic_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c['address']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    c['clinic_code']?.toString() ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textMuted),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClinicDetailScreen(
                        clinicId: c['id'] as int,
                        clinicName: c['clinic_name']?.toString() ?? 'Clinic',
                      ),
                    ),
                  ).then((_) => _load()),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
