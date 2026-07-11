import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/exercise.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

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
  final _searchCtrl = TextEditingController();
  Region? _activeRegion;
  int? _activeSubregion;
  int? _difficultyFilter;
  bool _loadingRegions = true;
  bool _loadingExercises = false;
  bool _saving = false;

  bool get _isAddingToExisting => widget.existingPrescriptionId != null;

  List<Exercise> get _filteredExercises {
    var list = _exercises;
    if (_difficultyFilter != null) {
      list = list.where((e) => e.difficultyLevel == _difficultyFilter).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) => e.exerciseName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _searchCtrl.addListener(() => setState(() {}));
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

  void _selectRegion(Region r) {
    setState(() {
      _activeRegion = r;
      _activeSubregion = null;
      _exercises = [];
      _difficultyFilter = null;
      _searchCtrl.clear();
    });
  }

  Future<void> _loadExercises(int subregionId) async {
    setState(() {
      _activeSubregion = subregionId;
      _loadingExercises = true;
      _difficultyFilter = null;
      _searchCtrl.clear();
    });
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
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_isAddingToExisting ? 'Add Exercises' : 'New Rx'),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        widget.patient.patientName.isNotEmpty ? widget.patient.patientName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.patient.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!_isAddingToExisting) ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _conditionCtrl,
                    label: 'Condition (optional)',
                    hint: 'e.g. Cervical Spondylosis',
                    prefixIcon: Icons.label_outline,
                  ),
                ],
                const SizedBox(height: 14),
                _stepLabel('1', 'Choose a body region'),
                const SizedBox(height: 8),
                _loadingRegions
                    ? const LinearProgressIndicator()
                    : SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _regions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => _regionChip(_regions[i]),
                        ),
                      ),
                if (_activeRegion != null) ...[
                  const SizedBox(height: 14),
                  _stepLabel('2', 'Choose an area'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activeRegion!.subregions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _subregionChip(_activeRegion!.subregions[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_activeSubregion != null) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(_searchCtrl.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _difficultyChip(null, 'All'),
                        const SizedBox(width: 8),
                        _difficultyChip(1, 'Beginner'),
                        const SizedBox(width: 8),
                        _difficultyChip(2, 'Intermediate'),
                        const SizedBox(width: 8),
                        _difficultyChip(3, 'Advanced'),
                        const SizedBox(width: 8),
                        _difficultyChip(4, 'Super'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(child: _exercisePanel()),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty ? null : _selectedBar(),
    );
  }

  Widget _stepLabel(String step, String text) {
    return Row(
      children: [
        CircleAvatar(radius: 9, backgroundColor: AppColors.primary, child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _regionChip(Region r) {
    final selected = _activeRegion?.id == r.id;
    return ChoiceChip(
      avatar: Icon(_regionIcon(r.regionName), size: 16, color: selected ? Colors.white : AppColors.primary),
      label: Text(r.regionName.replaceAll('_', ' ')),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      onSelected: (_) => _selectRegion(r),
    );
  }

  Widget _subregionChip(SubRegion s) {
    final selected = _activeSubregion == s.id;
    return ChoiceChip(
      label: Text(s.subRegionName),
      selected: selected,
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      onSelected: (_) => _loadExercises(s.id),
    );
  }

  Widget _difficultyChip(int? level, String label) {
    final selected = _difficultyFilter == level;
    final color = level == null ? AppColors.primary : _difficultyColor(level);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
      selected: selected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() => _difficultyFilter = level),
    );
  }

  IconData _regionIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('head') || n.contains('neck') || n.contains('face')) return Icons.face_outlined;
    if (n.contains('spine') || n.contains('back')) return Icons.accessibility_new;
    if (n.contains('upper')) return Icons.back_hand_outlined;
    if (n.contains('lower')) return Icons.directions_walk_outlined;
    if (n.contains('shoulder')) return Icons.accessibility_outlined;
    if (n.contains('knee') || n.contains('hip') || n.contains('pelvis')) return Icons.airline_seat_legroom_normal;
    return Icons.accessibility_new;
  }

  Widget _exercisePanel() {
    if (_activeSubregion == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Pick a body region and area above\nto browse exercises',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    if (_loadingExercises) return const Center(child: CircularProgressIndicator());

    final filtered = _filteredExercises;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _exercises.isEmpty ? 'No exercises in this area' : 'No exercises match your filters',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _exerciseCard(filtered[i]),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: picked ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: picked ? AppColors.primary.withOpacity(0.25) : Colors.black.withOpacity(0.06),
              blurRadius: picked ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
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
                        child: const Center(
                          child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                        ),
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

  Widget _selectedBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selected.length} exercise${_selected.length == 1 ? '' : 's'} selected',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton(
                onPressed: () => setState(_selected.clear),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _selectedThumb(_selected[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedThumb(Exercise e) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 52, height: 52, child: _exerciseImage(e.exerciseUrl)),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: GestureDetector(
            onTap: () => setState(() => _selected.removeWhere((x) => x.id == e.id)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
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
