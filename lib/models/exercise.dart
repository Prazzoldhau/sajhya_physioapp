class Region {
  final int id;
  final String regionName;
  final List<SubRegion> subregions;

  const Region({required this.id, required this.regionName, required this.subregions});

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as int,
        regionName: j['region_name'] as String,
        subregions: (j['subregions'] as List<dynamic>)
            .map((s) => SubRegion.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class SubRegion {
  final int id;
  final String subRegionName;

  const SubRegion({required this.id, required this.subRegionName});

  factory SubRegion.fromJson(Map<String, dynamic> j) => SubRegion(
        id: j['id'] as int,
        subRegionName: j['sub_region_name'] as String,
      );
}

class Exercise {
  final int id;
  final String exerciseName;
  final String exerciseType;
  final int difficultyLevel;
  final int defaultSets;
  final int defaultReps;
  final int holdTimeSec;
  final String exerciseDescription;
  final String exerciseUrl;
  final String subregion;

  const Exercise({
    required this.id,
    required this.exerciseName,
    required this.exerciseType,
    required this.difficultyLevel,
    required this.defaultSets,
    required this.defaultReps,
    required this.holdTimeSec,
    required this.exerciseDescription,
    required this.exerciseUrl,
    required this.subregion,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as int,
        exerciseName: j['exercise_name'] as String,
        exerciseType: j['exercise_type'] as String? ?? '',
        difficultyLevel: j['difficulty_level'] as int? ?? 1,
        defaultSets: j['default_sets'] as int? ?? 3,
        defaultReps: j['default_reps'] as int? ?? 10,
        holdTimeSec: j['hold_time_sec'] as int? ?? 0,
        exerciseDescription: j['exercise_description'] as String? ?? '',
        exerciseUrl: j['exercise_url'] as String? ?? '',
        subregion: j['subregion'] as String? ?? '',
      );

  String get difficultyLabel {
    switch (difficultyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Super Level';
      default:
        return 'Unknown';
    }
  }
}
