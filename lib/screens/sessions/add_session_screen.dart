import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class AddSessionScreen extends StatefulWidget {
  final Patient patient;

  const AddSessionScreen({super.key, required this.patient});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preNotesCtrl = TextEditingController();
  final _sessionNoteCtrl = TextEditingController();
  String _response = '';
  bool _loading = false;

  final _responses = ['excellent', 'good', 'fair', 'poor'];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await ApiService().addSession(
        widget.patient.patientCode,
        sessionNote: _sessionNoteCtrl.text.trim(),
        preNotes: _preNotesCtrl.text.trim().isEmpty ? null : _preNotesCtrl.text.trim(),
        treatmentResponse: _response.isEmpty ? null : _response,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session ${result['session_number']} recorded'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
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
      appBar: AppBar(title: Text('Add Session — ${widget.patient.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pre-session notes', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _preNotesCtrl,
                label: 'Pre-session assessment (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Session note', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _sessionNoteCtrl,
                label: 'What was done today?',
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Treatment response', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _responses.map((r) => ChoiceChip(
                      label: Text(r),
                      selected: _response == r,
                      onSelected: (_) => setState(() => _response = r == _response ? '' : r),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _response == r ? Colors.white : AppColors.textPrimary,
                      ),
                    )).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
