import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../patients/create_patient_screen.dart';
import '../patients/patient_detail_screen.dart';

/// Shows a single clinic's details and the patients registered under it
/// (mirrors the web clinic_detail view: patients this physio created at
/// this clinic).
class ClinicDetailScreen extends StatefulWidget {
  final int clinicId;
  final String clinicName;

  const ClinicDetailScreen({super.key, required this.clinicId, required this.clinicName});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  Map<String, dynamic>? _clinic;
  List<Patient> _patients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiService().getClinicDetail(widget.clinicId);
      final clinic = data['clinic'] as Map<String, dynamic>;
      final patients = (data['patients'] as List).map((p) => Patient.fromJson(p as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _clinic = clinic; _patients = patients; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clinicName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => CreatePatientScreen(clinicId: widget.clinicId, clinicName: widget.clinicName)),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Patient'),
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
                    child: Text('Could not load clinic.\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            );
          }
          if (_clinic == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _clinicHeader(_clinic!),
              const SizedBox(height: 20),
              const Text('Patients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              if (_patients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No patients registered at this clinic yet.', style: TextStyle(color: AppColors.textMuted))),
                )
              else
                for (final p in _patients)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(p.patientName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(p.patientDiagnosis, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(p.patientCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textMuted)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: p)),
                      ).then((_) => _load()),
                    ),
                  ),
            ],
          );
        }),
      ),
    );
  }

  Widget _clinicHeader(Map<String, dynamic> c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['clinic_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(c['clinic_code']?.toString() ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, c['address']?.toString() ?? ''),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, c['phone']?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
