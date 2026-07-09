import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/exercise.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PrescriptionScreen extends StatefulWidget {
  final Patient patient;
  final int? existingPrescriptionId;

  const PrescriptionScreen({super.key, required this.patient, this.existingPrescriptionId});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Region> _regions = [];
  List<Exercise> _exercises = [];
  final List<Exercise> _selected = [];
  final _conditionCtrl = TextEditingController();
  int? _activeSubregion;
  bool _loadingRegions = true;
  bool _loadingExercises = false;
  bool _saving = false;

  bool get _isAddingToExisting => widget.existingPrescriptionId != null;

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
      if (_isAddingToExisting) {
        await ApiService().addExercisesToPrescription(
          widget.existingPrescriptionId!,
          _selected.map((e) => e.id).toList(),
        );
      } else {
        await ApiService().createPrescription(
          widget.patient.patientCode,
          _selected.map((e) => e.id).toList(),
          conditionLabel: _conditionCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAddingToExisting ? 'Exercises added!' : 'Prescription saved!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _conditionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAddingToExisting ? 'Add Exercises — ${widget.patient.patientName}' : 'New Rx — ${widget.patient.patientName}'),
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
      body: Column(
        children: [
          if (!_isAddingToExisting)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                controller: _conditionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Condition (optional)',
                  hintText: 'e.g. Cervical Spondylosis',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ),
          Expanded(
            child: Row(
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
          ),
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

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _exercises.length,
      itemBuilder: (_, i) => _exerciseCard(_exercises[i]),
    );
  }

  Widget _exerciseCard(Exercise e) {
    final picked = _selected.any((x) => x.id == e.id);
    final color = _difficultyColor(e.difficultyLevel);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (picked) {
            _selected.removeWhere((x) => x.id == e.id);
          } else {
            _selected.add(e);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: picked ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _exerciseImage(e.exerciseUrl),
                    if (picked)
                      Container(
                        color: AppColors.primary.withOpacity(0.35),
                        child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 32)),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(e.difficultyLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text('${e.defaultSets}×${e.defaultReps}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 28)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        );
      },
    );
  }

  Color _difficultyColor(int level) => switch (level) {
        1 => const Color(0xFF4CAF50),
        2 => const Color(0xFF8BC34A),
        3 => const Color(0xFFFFC107),
        4 => const Color(0xFFFF9800),
        _ => const Color(0xFF757575),
      };
}
