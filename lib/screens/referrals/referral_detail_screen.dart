import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReferralDetailScreen extends StatefulWidget {
  final String referralCode;

  const ReferralDetailScreen({super.key, required this.referralCode});

  @override
  State<ReferralDetailScreen> createState() => _ReferralDetailScreenState();
}

class _ReferralDetailScreenState extends State<ReferralDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService().searchReferral(widget.referralCode);
      setState(() => _data = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.referralCode),
        actions: [
          if (d != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.referralCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text('Not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status
                      Center(child: _statusBadge(d['status'] as String? ?? '')),
                      const SizedBox(height: 24),

                      // Share code card
                      Card(
                        color: AppColors.primary.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Share this code with the receiving physio', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(
                                widget.referralCode,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => Clipboard.setData(ClipboardData(text: widget.referralCode)),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Patient info
                      _section('Patient', [
                        _row('Name', d['patient_name'] as String? ?? ''),
                        if ((d['patient_contact'] as String?)?.isNotEmpty == true)
                          _row('Contact', d['patient_contact'] as String),
                        _row('Diagnosis', d['patient_diagnosis'] as String? ?? ''),
                        if (d['patient_code'] != null)
                          _row('Patient Code', d['patient_code'] as String),
                      ]),
                      const SizedBox(height: 12),

                      // Referral info
                      _section('Referral Details', [
                        _row('Referred by', d['referred_by'] as String? ?? 'Unknown'),
                        if ((d['referred_to'] as String?) != null)
                          _row('Referred to', d['referred_to'] as String),
                        _row('Reason', d['reason'] as String? ?? ''),
                        if ((d['notes'] as String?)?.isNotEmpty == true)
                          _row('Notes', d['notes'] as String),
                        _row('Date', _fmt(d['created_at'] as String? ?? '')),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _statusBadge(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _color(s).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          s.toUpperCase().replaceAll('_', ' '),
          style: TextStyle(color: _color(s), fontWeight: FontWeight.bold),
        ),
      );

  Widget _section(String title, List<Widget> rows) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
              const Divider(),
              ...rows,
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Color _color(String s) => switch (s) {
        'pending' => AppColors.warning,
        'accepted' => const Color(0xFF0DCAF0),
        'in_progress' => AppColors.primary,
        'completed' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.textMuted,
      };

  String _fmt(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }
}
