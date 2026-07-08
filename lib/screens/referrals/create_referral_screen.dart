import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import 'referral_detail_screen.dart';

class CreateReferralScreen extends StatefulWidget {
  const CreateReferralScreen({super.key});

  @override
  State<CreateReferralScreen> createState() => _CreateReferralScreenState();
}

class _CreateReferralScreenState extends State<CreateReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  int? _selectedUserId;
  String _selectedUserName = '';
  bool _loading = false;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      _users = await ApiService().getUsers();
    } catch (_) {}
    if (mounted) setState(() => _loadingUsers = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await ApiService().createReferral(
        patientName: _nameCtrl.text.trim(),
        patientDiagnosis: _diagnosisCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
        patientContact: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        referredToId: _selectedUserId,
      );

      if (!mounted) return;
      final code = result['referral_code'] as String;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral $code created'), backgroundColor: AppColors.success),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReferralDetailScreen(referralCode: code)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Referral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scanner placeholder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 32, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text('Image scanner coming soon', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              CustomTextField(controller: _nameCtrl, label: 'Patient Name', prefixIcon: Icons.person_outline, validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              CustomTextField(controller: _contactCtrl, label: 'Contact (optional)', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: _diagnosisCtrl, label: 'Diagnosis', prefixIcon: Icons.medical_information_outlined, validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 24),

              const Text('Refer To', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              _loadingUsers
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<int?>(
                      value: _selectedUserId,
                      decoration: const InputDecoration(labelText: 'Physio / User (optional)', prefixIcon: Icon(Icons.person_search_outlined)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('— Leave open (anyone can claim) —')),
                        ..._users.map((u) => DropdownMenuItem<int?>(
                              value: u['id'] as int,
                              child: Text(u['full_name'] as String? ?? u['username'] as String),
                            )),
                      ],
                      onChanged: (v) => setState(() { _selectedUserId = v; _selectedUserName = v == null ? '' : (_users.firstWhere((u) => u['id'] == v)['full_name'] as String? ?? ''); }),
                    ),
              const SizedBox(height: 24),

              const Text('Referral Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              CustomTextField(controller: _reasonCtrl, label: 'Reason for referral', maxLines: 3, validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              CustomTextField(controller: _notesCtrl, label: 'Additional notes (optional)', maxLines: 2),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Referral'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
