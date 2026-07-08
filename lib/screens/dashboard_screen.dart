import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'patients/patient_detail_screen.dart';
import 'patients/create_patient_screen.dart';
import 'referrals/create_referral_screen.dart';
import 'referrals/find_referral_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onNavigateToPatients;
  final VoidCallback? onNavigateToReferrals;

  const DashboardScreen({
    super.key,
    required this.userData,
    this.onNavigateToPatients,
    this.onNavigateToReferrals,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getDashboard();
      setState(() => _stats = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _name {
    final n = widget.userData['full_name']?.toString().trim();
    return (n != null && n.isNotEmpty) ? n : widget.userData['username'] as String? ?? 'Physio';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF1A8FE3)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    _name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userData['user_type']?.toString().toUpperCase() ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),

          // Stat cards — overlapping the header
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : Row(
                        children: [
                          _statCard('Patients', _stats?['total_patients'] ?? 0, Icons.people_outline, AppColors.primary),
                          const SizedBox(width: 10),
                          _statCard('Sessions', _stats?['total_sessions'] ?? 0, Icons.notes_outlined, AppColors.secondary),
                          const SizedBox(width: 10),
                          _statCard('Pending\nReferrals', _stats?['pending_referrals'] ?? 0, Icons.inbox_outlined, AppColors.warning),
                        ],
                      ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _action(Icons.person_add_outlined, 'Add\nPatient', AppColors.primary, () async {
                        final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePatientScreen()));
                        if (created == true) _load();
                      }),
                      _action(Icons.fitness_center_outlined, 'New\nRx', AppColors.secondary, () {
                        widget.onNavigateToPatients?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select a patient first to create a prescription')),
                        );
                      }),
                      _action(Icons.send_outlined, 'Refer\nPatient', const Color(0xFF0DCAF0), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReferralScreen())).then((_) => _load());
                      }),
                      _action(Icons.search_outlined, 'Find\nReferral', AppColors.success, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FindReferralScreen())).then((_) => _load());
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recent patients
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Patients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                  if (widget.onNavigateToPatients != null)
                    TextButton(
                      onPressed: widget.onNavigateToPatients,
                      child: const Text('See all'),
                    ),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
          else if ((_stats?['recent_patients'] as List?)?.isEmpty != false)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No patients yet. Add your first patient!', style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final raw = (_stats!['recent_patients'] as List)[i] as Map<String, dynamic>;
                  final p = Patient.fromJson(raw);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Card(
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
                  );
                },
                childCount: (_stats?['recent_patients'] as List?)?.length ?? 0,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
