import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../prescriptions/prescription_screen.dart';
import '../sessions/add_session_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ApiService().getPatientDetail(widget.patient.patientCode);
      setState(() => _detail = d);
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

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.patientName),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Prescriptions'),
            Tab(icon: Icon(Icons.notes), text: 'Sessions'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Patient info header
                Container(
                  color: AppColors.primary.withOpacity(0.05),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          p.patientName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 22, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(p.patientDiagnosis, style: const TextStyle(color: AppColors.textMuted)),
                            Text(p.patientCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text('${p.completedSession}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const Text('sessions', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _prescriptionsTab(),
                      _sessionsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (_tabs.index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrescriptionScreen(patient: widget.patient)),
                  ).then((_) => _load());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddSessionScreen(patient: widget.patient)),
                  ).then((_) => _load());
                }
              },
              icon: const Icon(Icons.add),
              label: Text(_tabs.index == 0 ? 'New Rx' : 'Add Note'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _prescriptionsTab() {
    final prescriptions = (_detail?['prescriptions'] as List<dynamic>?) ?? [];
    if (prescriptions.isEmpty) {
      return _empty('No prescriptions yet', Icons.fitness_center_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: prescriptions.length,
      itemBuilder: (_, i) {
        final rx = prescriptions[i] as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(rx['status'] as String? ?? 'active').withOpacity(0.15),
              child: Icon(Icons.fitness_center, color: _statusColor(rx['status'] as String? ?? 'active')),
            ),
            title: Text('Prescription #${rx['id']}'),
            subtitle: Text('${rx['exercise_count']} exercises • ${rx['status']}'),
            trailing: Text(
              _formatDate(rx['created_at'] as String? ?? ''),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }

  Widget _sessionsTab() {
    final sessions = (_detail?['sessions'] as List<dynamic>?) ?? [];
    if (sessions.isEmpty) {
      return _empty('No sessions recorded', Icons.notes_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i] as Map<String, dynamic>;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text('${s['session_number']}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Session ${s['session_number']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _formatDate(s['session_date'] as String? ?? ''),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if ((s['session_note'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(s['session_note'] as String, style: const TextStyle(color: AppColors.textMuted)),
                ],
                if ((s['treatment_response'] as String?)?.isNotEmpty == true)
                  Chip(label: Text(s['treatment_response'] as String)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  Color _statusColor(String s) => switch (s) {
        'active' => AppColors.success,
        'completed' => AppColors.primary,
        _ => AppColors.textMuted,
      };

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}
