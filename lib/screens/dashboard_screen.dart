import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_tile.dart';
import 'patients/patient_detail_screen.dart';
import 'more/clinics_screen.dart';
import 'more/home_visit_screen.dart';
import 'more/shop_screen.dart';
import 'more/ip_request_screen.dart';
import 'more/discussion_forum_screen.dart';

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

  // Enterprise accounts get a stripped-down dashboard (IP Request only).
  bool get _isEnterprise => (widget.userData['user_type']?.toString().toLowerCase() ?? '').contains('enterprise');

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
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
              offset: const Offset(0, -16),
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

          // Quick actions — enterprise accounts only manage IP requests here;
          // everyone else gets the full set of platform features.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: FeatureTileRow(
                title: 'Quick Actions',
                tiles: _isEnterprise
                    ? [
                        FeatureTile(
                          icon: Icons.assignment_add,
                          label: 'IP\nRequest',
                          color: AppColors.accentIndigo,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IpRequestScreen())),
                        ),
                      ]
                    : [
                        FeatureTile(
                          icon: Icons.local_hospital_outlined,
                          label: 'My\nClinics',
                          color: AppColors.primary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClinicsScreen())),
                        ),
                        FeatureTile(
                          icon: Icons.home_work_outlined,
                          label: 'Home\nVisit',
                          color: AppColors.accentOrange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeVisitScreen())),
                        ),
                        FeatureTile(
                          icon: Icons.storefront_outlined,
                          label: 'Shop',
                          color: AppColors.accentTeal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                        ),
                        FeatureTile(
                          icon: Icons.assignment_add,
                          label: 'IP\nRequest',
                          color: AppColors.accentIndigo,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IpRequestScreen())),
                        ),
                        FeatureTile(
                          icon: Icons.forum_outlined,
                          label: 'Discussion\nForum',
                          color: AppColors.accentPurple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscussionForumScreen())),
                        ),
                      ],
              ),
            ),
          ),

          // Recent patients — not relevant to enterprise accounts, which
          // operate at the clinic/branch level rather than per-patient.
          if (!_isEnterprise) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: SectionHeader(
                  title: 'Recent Patients',
                  actionLabel: widget.onNavigateToPatients != null ? 'See all' : null,
                  onAction: widget.onNavigateToPatients,
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
          ],

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
}
