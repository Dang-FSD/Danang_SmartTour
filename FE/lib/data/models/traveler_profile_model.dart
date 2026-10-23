class TravelerProfile {
  final String id;
  final String displayName;
  final String fitnessLevel; // 'low', 'moderate', 'high'
  final String? dietRule; // 'halal', 'vegan', 'vegetarian'
  final String? allergen; // 'peanut', 'seafood', etc.
  final String? allergenSeverity; // 'mild', 'severe'
  final String? medicalCondition; // 'heart_disease'
  final DateTime? createdAt;

  const TravelerProfile({
    required this.id,
    required this.displayName,
    this.fitnessLevel = 'moderate',
    this.dietRule,
    this.allergen,
    this.allergenSeverity,
    this.medicalCondition,
    this.createdAt,
  });

  TravelerProfile copyWith({
    String? id,
    String? displayName,
    String? fitnessLevel,
    String? dietRule,
    String? allergen,
    String? allergenSeverity,
    String? medicalCondition,
    DateTime? createdAt,
  }) {
    return TravelerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietRule: dietRule ?? this.dietRule,
      allergen: allergen ?? this.allergen,
      allergenSeverity: allergenSeverity ?? this.allergenSeverity,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static bool isValidUuid(String val) {
    final regex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return regex.hasMatch(val);
  }

  String get validUuid {
    if (isValidUuid(id)) return id;
    if (id == 'user-halal-01') return '00000000-0000-0000-0000-000000000001';
    if (id == 'user-heart-02') return '00000000-0000-0000-0000-000000000002';
    if (id == 'user-peanut-03') return '00000000-0000-0000-0000-000000000003';
    if (id == 'user-fit-04') return '00000000-0000-0000-0000-000000000004';
    final clean = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final padded = (clean.isEmpty ? '1' : clean).padLeft(12, '0');
    final suffix = padded.length > 12 ? padded.substring(padded.length - 12) : padded;
    return '00000000-0000-0000-0000-$suffix';
  }

  Map<String, dynamic> toProfileMap() {
    return {
      'id': validUuid,
      'display_name': displayName,
      'fitness_level': fitnessLevel,
    };
  }

  Map<String, dynamic> toHealthProfileMap() {
    return {
      'user_id': validUuid,
      'diet_rule': dietRule,
      'allergen': allergen,
      'severity': allergenSeverity,
      'medical_condition': medicalCondition,
    };
  }

  factory TravelerProfile.fromMaps(
    Map<String, dynamic> profileMap,
    Map<String, dynamic>? healthMap,
  ) {
    return TravelerProfile(
      id: profileMap['id']?.toString() ?? '',
      displayName: profileMap['display_name']?.toString() ?? 'Traveler',
      fitnessLevel: profileMap['fitness_level']?.toString() ?? 'moderate',
      dietRule: healthMap?['diet_rule']?.toString(),
      allergen: healthMap?['allergen']?.toString(),
      allergenSeverity: healthMap?['severity']?.toString(),
      medicalCondition: healthMap?['medical_condition']?.toString(),
      createdAt: profileMap['created_at'] != null
          ? DateTime.tryParse(profileMap['created_at'].toString())
          : null,
    );
  }

  // Các preset mẫu tương ứng với 4 nhóm khách trong Danang_SmartTour_DB.sql
  static const TravelerProfile sampleHalal = TravelerProfile(
    id: '00000000-0000-0000-0000-000000000001',
    displayName: 'Ali (Halal Tourist)',
    fitnessLevel: 'moderate',
    dietRule: 'halal',
  );

  static const TravelerProfile sampleHeart = TravelerProfile(
    id: '00000000-0000-0000-0000-000000000002',
    displayName: 'John (Cardiac Patient)',
    fitnessLevel: 'low',
    medicalCondition: 'heart_disease',
  );

  static const TravelerProfile samplePeanut = TravelerProfile(
    id: '00000000-0000-0000-0000-000000000003',
    displayName: 'Emma (Peanut Allergy)',
    fitnessLevel: 'moderate',
    allergen: 'peanut',
    allergenSeverity: 'severe',
  );

  static const TravelerProfile sampleFitVegan = TravelerProfile(
    id: '00000000-0000-0000-0000-000000000004',
    displayName: 'Nam (Vegan & Fit)',
    fitnessLevel: 'high',
    dietRule: 'vegan',
  );
}
