import 'package:flutter/material.dart';
import '../../models/referral.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'create_referral_screen.dart';
import 'find_referral_screen.dart';
import 'referral_detail_screen.dart';

class ReferralListScreen extends StatefulWidget {
  final bool embedded;

  const ReferralListScreen({super.key, this.embedded = false});

  @override
  ReferralListScreenState createState() => ReferralListScreenState();
}

class ReferralListScreenState extends State<ReferralListScreen> {
  List<Referral> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService().getReferrals();
      setState(() => _referrals = raw.map(Referral.fromJson).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FindReferralScreen()),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.search),
                  label: const Text('Find by Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateReferralScreen()),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.send),
                  label: const Text('New Referral'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _referrals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No referrals sent yet', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _referrals.length,
                        itemBuilder: (_, i) => _referralCard(_referrals[i]),
                      ),
                    ),
        ),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: content,
    );
  }

  Widget _referralCard(Referral r) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: r.statusColor.withOpacity(0.15),
          child: Icon(Icons.send, color: r.statusColor, size: 18),
        ),
        title: Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.patientDiagnosis, maxLines: 1, overflow: TextOverflow.ellipsis),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: r.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(r.status.toUpperCase(), style: TextStyle(fontSize: 10, color: r.statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          r.referralCode,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMuted),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReferralDetailScreen(referralCode: r.referralCode)),
        ).then((_) => _load()),
      ),
    );
  }
}
