import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/exercise.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PrescriptionScreen extends StatefulWidget {
  final Patient patient;

  const PrescriptionScreen({super.key, required this.patient});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Region> _regions = [];
  List<Exercise> _exercises = [];
  final List<Exercise> _selected = [];
  int? _activeSubregion;
  bool _loadingRegions = true;
  bool _loadingExercises = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final raw = await ApiService().getRegions();
      setState(() => _regions = raw.map(Region.fromJson).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadExercises(int subregionId) async {
    setState(() { _activeSubregion = subregionId; _loadingExercises = true; });
    try {
      final raw = await ApiService().getExercises(subregionId: subregionId);
      setState(() => _exercises = raw.map(Exercise.fromJson).toList());
    } finally {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  Future<void> _savePrescription() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().createPrescription(
        widget.patient.patientCode,
        _selected.map((e) => e.id).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Rx — ${widget.patient.patientName}'),
        actions: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saving ? null : _savePrescription,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save (${_selected.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar: regions + subregions
          SizedBox(
            width: 160,
            child: _loadingRegions
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: _regions.map((r) => _regionTile(r)).toList(),
                  ),
          ),
          const VerticalDivider(width: 1),
          // Exercise list
          Expanded(child: _exercisePanel()),
        ],
      ),
      // Selected exercises bottom sheet
      bottomNavigationBar: _selected.isEmpty
          ? null
          : Container(
              color: AppColors.primary.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selected.length} exercise(s) selected',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _regionTile(Region r) => ExpansionTile(
        title: Text(r.regionName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        children: r.subregions
            .map((s) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  title: Text(s.subRegionName, style: const TextStyle(fontSize: 12)),
                  selected: _activeSubregion == s.id,
                  selectedColor: AppColors.primary,
                  onTap: () => _loadExercises(s.id),
                ))
            .toList(),
      );

  Widget _exercisePanel() {
    if (_activeSubregion == null) {
      return const Center(
        child: Text('Select a body region to browse exercises', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_loadingExercises) return const Center(child: CircularProgressIndicator());
    if (_exercises.isEmpty) return const Center(child: Text('No exercises in this region'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _exercises.length,
      itemBuilder: (_, i) {
        final e = _exercises[i];
        final picked = _selected.any((x) => x.id == e.id);
        return Card(
          child: CheckboxListTile(
            value: picked,
            onChanged: (_) {
              setState(() {
                if (picked) {
                  _selected.removeWhere((x) => x.id == e.id);
                } else {
                  _selected.add(e);
                }
              });
            },
            title: Text(e.exerciseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${e.difficultyLabel} • ${e.defaultSets}×${e.defaultReps}', style: const TextStyle(fontSize: 11)),
            secondary: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('${e.difficultyLevel}', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
            ),
            activeColor: AppColors.primary,
          ),
        );
      },
    );
  }
}
