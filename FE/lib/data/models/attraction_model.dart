import 'package:latlong2/latlong.dart';

class Attraction {
  final int id;
  final String nameVi;
  final String category; // 'culture', 'sport'
  final String difficulty; // 'easy', 'moderate', 'hard'
  final bool isOverloaded;
  final double latitude;
  final double longitude;
  final String? description;
  final String? healthWarning;
  final int? alternativeId;

  const Attraction({
    required this.id,
    required this.nameVi,
    required this.category,
    this.difficulty = 'easy',
    this.isOverloaded = false,
    required this.latitude,
    required this.longitude,
    this.description,
    this.healthWarning,
    this.alternativeId,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nameVi: json['name_vi']?.toString() ?? '',
      category: json['category']?.toString() ?? 'culture',
      difficulty: json['difficulty']?.toString() ?? 'easy',
      isOverloaded: json['is_overloaded'] == true,
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '16.0544') ?? 16.0544,
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '108.2022') ?? 108.2022,
      description: json['description']?.toString(),
      healthWarning: json['health_warning']?.toString(),
      alternativeId: json['alternative_id'] != null
          ? int.tryParse(json['alternative_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_vi': nameVi,
      'category': category,
      'difficulty': difficulty,
      'is_overloaded': isOverloaded,
      'latitude': latitude,
      'longitude': longitude,
      if (description != null) 'description': description,
      if (healthWarning != null) 'health_warning': healthWarning,
      if (alternativeId != null) 'alternative_id': alternativeId,
    };
  }
}
