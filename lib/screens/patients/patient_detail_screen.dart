import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  List<Map<String, dynamic>> _prescriptions = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  String get _qrToken => (_detail?['patient']?['qr_token'] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final code = widget.patient.patientCode;
      final results = await Future.wait([
        api.getPatientDetail(code),
        api.getPrescriptions(code),
        api.getPatientStats(code),
      ]);
      setState(() {
        _detail = results[0] as Map<String, dynamic>;
        _prescriptions = results[1] as List<Map<String, dynamic>>;
        _stats = results[2] as Map<String, dynamic>;
      });
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

  Future<void> _toggleExercise(int exerciseId, bool value) async {
    try {
      await ApiService().toggleExerciseCompletion(exerciseId, isCompleted: value);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _removeExercise(int exerciseId) async {
    try {
      await ApiService().removeExerciseFromPrescription(exerciseId);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _editExerciseParams(Map<String, dynamic> ex) async {
    final setsCtrl = TextEditingController(text: '${ex['sets'] ?? 3}');
    final repsCtrl = TextEditingController(text: '${ex['reps'] ?? 10}');
    final holdCtrl = TextEditingController(text: '${ex['hold_time_sec'] ?? 0}');
    final restCtrl = TextEditingController(text: '${ex['rest_time_sec'] ?? 60}');
    bool morning = ex['schedule_morning'] == true;
    bool day = ex['schedule_day'] == true;
    bool evening = ex['schedule_evening'] == true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex['exercise_name']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: setsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sets'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: holdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Hold (sec)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: restCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rest (sec)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('When', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('🌅 Morning'),
                        selected: morning,
                        onSelected: (v) => setSheetState(() => morning = v),
                      ),
                      FilterChip(
                        label: const Text('🌤️ Day'),
                        selected: day,
                        onSelected: (v) => setSheetState(() => day = v),
                      ),
                      FilterChip(
                        label: const Text('🌙 Evening'),
                        selected: evening,
                        onSelected: (v) => setSheetState(() => evening = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    try {
      await ApiService().updateExerciseParams(
        ex['id'] as int,
        sets: int.tryParse(setsCtrl.text),
        reps: int.tryParse(repsCtrl.text),
        holdTimeSec: int.tryParse(holdCtrl.text),
        restTimeSec: int.tryParse(restCtrl.text),
        scheduleMorning: morning,
        scheduleDay: day,
        scheduleEvening: evening,
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _addExercisesTo(int prescriptionId) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionScreen(patient: widget.patient, existingPrescriptionId: prescriptionId),
      ),
    );
    if (added == true) _load();
  }

  void _showQrDialog() {
    final token = _qrToken;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${widget.patient.patientName} — QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: token, size: 220, backgroundColor: Colors.white),
            const SizedBox(height: 16),
            const Text('Secret code', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            SelectableText(token, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy code'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.patientName),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Rx'),
            Tab(icon: Icon(Icons.track_changes_outlined), text: 'Track'),
            Tab(icon: Icon(Icons.notes), text: 'Sessions'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Stats'),
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
                      if (_qrToken.isNotEmpty)
                        IconButton(
                          onPressed: _showQrDialog,
                          icon: const Icon(Icons.qr_code_2, color: AppColors.primary),
                          tooltip: 'Show QR code',
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _prescriptionsTab(),
                      _trackTab(),
                      _sessionsTab(),
                      _statsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _loading
          ? null
          : ListenableBuilder(
              listenable: _tabs,
              builder: (_, __) {
                if (_tabs.index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PrescriptionScreen(patient: widget.patient)),
                      ).then((_) => _load());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Rx'),
                    backgroundColor: AppColors.primary,
                  );
                }
                if (_tabs.index == 2) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddSessionScreen(patient: widget.patient)),
                      ).then((_) => _load());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Note'),
                    backgroundColor: AppColors.primary,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _prescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return _empty('No prescriptions yet', Icons.fitness_center_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _prescriptions.length,
      itemBuilder: (_, i) {
        final rx = _prescriptions[i];
        final label = (rx['condition_label']?.toString().isNotEmpty == true)
            ? rx['condition_label'].toString()
            : 'Prescription #${rx['id']}';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(rx['status'] as String? ?? 'active').withOpacity(0.15),
              child: Icon(Icons.fitness_center, color: _statusColor(rx['status'] as String? ?? 'active')),
            ),
            title: Text(label),
            subtitle: Text('${rx['total_exercises']} exercises • ${rx['status']}'),
            trailing: Text(
              _formatDate(rx['created_at'] as String? ?? ''),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            onTap: () => _tabs.animateTo(1),
          ),
        );
      },
    );
  }

  Widget _trackTab() {
    if (_prescriptions.isEmpty) {
      return _empty('No prescriptions to track yet', Icons.track_changes_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _prescriptions.length,
      itemBuilder: (_, i) => _trackCard(_prescriptions[i]),
    );
  }

  Widget _trackCard(Map<String, dynamic> rx) {
    final exercises = ((rx['exercises'] as List?) ?? []).cast<Map<String, dynamic>>();
    final total = rx['total_exercises'] as int? ?? exercises.length;
    final completed = rx['completed_exercises'] as int? ?? exercises.where((e) => e['is_completed'] == true).length;
    final progress = total > 0 ? completed / total : 0.0;
    final status = rx['status'] as String? ?? 'active';
    final label = (rx['condition_label']?.toString().isNotEmpty == true) ? rx['condition_label'].toString() : 'Prescription #${rx['id']}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 4),
            Text('$completed / $total exercises completed', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const Divider(height: 20),
            if (exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No exercises assigned yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              )
            else
              for (final ex in exercises) _exerciseRow(ex),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addExercisesTo(rx['id'] as int),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseRow(Map<String, dynamic> ex) {
    final completed = ex['is_completed'] == true;
    final imageUrl = ex['exercise_url']?.toString() ?? '';
    final schedule = [
      if (ex['schedule_morning'] == true) '🌅',
      if (ex['schedule_day'] == true) '🌤️',
      if (ex['schedule_evening'] == true) '🌙',
    ].join(' ');
    final holdSec = ex['hold_time_sec'] as int? ?? 0;
    final restSec = ex['rest_time_sec'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: completed,
            activeColor: AppColors.success,
            onChanged: (v) => _toggleExercise(ex['id'] as int, v ?? false),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 36,
              height: 36,
              child: imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined, size: 16, color: AppColors.textMuted),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined, size: 16, color: AppColors.textMuted),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex['exercise_name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    Text('${ex['sets']}×${ex['reps']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (holdSec > 0) Text('Hold ${holdSec}s', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (restSec > 0) Text('Rest ${restSec}s', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (schedule.isNotEmpty) Text(schedule, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            onPressed: () => _editExerciseParams(ex),
            tooltip: 'Edit dose & schedule',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
            onPressed: () => _removeExercise(ex['id'] as int),
            tooltip: 'Remove exercise',
          ),
        ],
      ),
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

  Widget _statsTab() {
    final s = _stats;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final overall = (s['overall_completion_percentage'] as num? ?? 0).toDouble();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _statTile('Prescriptions', '${s['total_prescriptions']}', Icons.fitness_center, AppColors.primary),
              const SizedBox(width: 10),
              _statTile('Active', '${s['active_prescriptions']}', Icons.play_circle_outline, AppColors.success),
              const SizedBox(width: 10),
              _statTile('Completed', '${s['completed_prescriptions']}', Icons.check_circle_outline, AppColors.info),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statTile('Sessions', '${s['total_sessions']}', Icons.notes_outlined, AppColors.secondary),
              const SizedBox(width: 10),
              _statTile('Exercises', '${s['completed_exercises']}/${s['total_exercises']}', Icons.checklist, AppColors.accentTeal),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Overall Exercise Adherence', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overall / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 6),
          Text('$overall% complete', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
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
