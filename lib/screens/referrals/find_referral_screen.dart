import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'referral_detail_screen.dart';

class FindReferralScreen extends StatefulWidget {
  const FindReferralScreen({super.key});

  @override
  State<FindReferralScreen> createState() => _FindReferralScreenState();
}

class _FindReferralScreenState extends State<FindReferralScreen> {
  final _codeCtrl = TextEditingController();
  Map<String, dynamic>? _referral;
  bool _loading = false;
  String _error = '';

  Future<void> _search() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = ''; _referral = null; });

    try {
      final result = await ApiService().searchReferral(code);
      setState(() => _referral = result);
    } catch (e) {
      setState(() => _error = 'Referral "$code" not found.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    if (_referral == null) return;
    final code = _referral!['referral_code'] as String;
    final patientName = _referral!['patient_name'] as String;
    final patientDiagnosis = _referral!['patient_diagnosis'] as String;
    final patientContact = _referral!['patient_contact'] as String? ?? '';

    try {
      await ApiService().acceptReferral(
        code,
        patientName: patientName,
        patientDiagnosis: patientDiagnosis,
        patientContact: patientContact.isEmpty ? null : patientContact,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral accepted — patient created'), backgroundColor: AppColors.success),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReferralDetailScreen(referralCode: code)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _reject() async {
    if (_referral == null) return;
    final code = _referral!['referral_code'] as String;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Referral'),
        content: const Text('Are you sure you want to reject this referral?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().rejectReferral(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral rejected'), backgroundColor: AppColors.warning),
      );
      setState(() => _referral = null);
      _codeCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Referral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the referral code shared by the referring physio / doctor / nurse',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'REF-XXXXXX',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onFieldSubmitted: (_) => _search(),
                    style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 52)),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_error, style: const TextStyle(color: AppColors.danger)),
              ),
            if (_referral != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _referral!['referral_code'] as String,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _statusChip(_referral!['status'] as String? ?? 'pending'),
                        ],
                      ),
                      const Divider(),
                      _infoRow('Patient', _referral!['patient_name'] as String? ?? ''),
                      _infoRow('Diagnosis', _referral!['patient_diagnosis'] as String? ?? ''),
                      _infoRow('Referred by', _referral!['referred_by'] as String? ?? 'Unknown'),
                      _infoRow('Reason', _referral!['reason'] as String? ?? ''),
                      if ((_referral!['referred_to'] as String?) != null)
                        _infoRow('Assigned to', _referral!['referred_to'] as String),
                      const SizedBox(height: 16),
                      if (_referral!['status'] == 'pending' && _referral!['is_addressed_to_me'] == true)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _accept,
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _reject,
                                icon: const Icon(Icons.close, color: AppColors.danger),
                                label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReferralDetailScreen(referralCode: _referral!['referral_code'] as String)),
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View Full Details'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.warning,
        'accepted' => const Color(0xFF0DCAF0),
        'completed' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.textMuted,
      };
}
