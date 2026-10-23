import 'package:danang_smarttour/core/utils/safety_evaluator.dart';

class ItineraryStop {
  final int? id;
  final int? itineraryId;
  final String timeSlot;
  final String name;
  final String category; // 'culture', 'sport', 'food'
  final SafetyLevel safetyLevel;
  final String safetyReason;
  final bool isRerouted;
  final String? originalName;
  final double? latitude;
  final double? longitude;
  final String? chefTicketWarning;

  const ItineraryStop({
    this.id,
    this.itineraryId,
    required this.timeSlot,
    required this.name,
    required this.category,
    required this.safetyLevel,
    required this.safetyReason,
    this.isRerouted = false,
    this.originalName,
    this.latitude,
    this.longitude,
    this.chefTicketWarning,
  });

  factory ItineraryStop.fromJson(Map<String, dynamic> json) {
    SafetyLevel parseSafetyLevel(String? val) {
      switch (val?.toUpperCase()) {
        case 'RED':
          return SafetyLevel.red;
        case 'YELLOW':
          return SafetyLevel.yellow;
        case 'GREEN':
        default:
          return SafetyLevel.green;
      }
    }

    return ItineraryStop(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      itineraryId: json['itinerary_id'] is int ? json['itinerary_id'] : int.tryParse(json['itinerary_id']?.toString() ?? ''),
      timeSlot: json['time_slot']?.toString() ?? '',
      name: json['name']?.toString() ?? json['dish_name']?.toString() ?? json['attraction_name']?.toString() ?? 'Stop',
      category: json['category']?.toString() ?? 'culture',
      safetyLevel: parseSafetyLevel(json['safety_level']?.toString()),
      safetyReason: json['safety_reason']?.toString() ?? 'Verified safe',
      isRerouted: json['is_rerouted'] == true,
      originalName: json['original_name']?.toString(),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      chefTicketWarning: json['chef_ticket_warning']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String levelString;
    switch (safetyLevel) {
      case SafetyLevel.red:
        levelString = 'RED';
        break;
      case SafetyLevel.yellow:
        levelString = 'YELLOW';
        break;
      case SafetyLevel.green:
        levelString = 'GREEN';
        break;
    }

    return {
      if (id != null) 'id': id,
      if (itineraryId != null) 'itinerary_id': itineraryId,
      'time_slot': timeSlot,
      'name': name,
      'category': category,
      'safety_level': levelString,
      'safety_reason': safetyReason,
      'is_rerouted': isRerouted,
      if (originalName != null) 'original_name': originalName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (chefTicketWarning != null) 'chef_ticket_warning': chefTicketWarning,
    };
  }
}

class Itinerary {
  final int? id;
  final String userId;
  final String title;
  final String objective; // 'culture', 'adventure', 'culinary'
  final String duration; // 'half_day', 'full_day', 'evening'
  final String status; // 'verified', 'draft'
  final String summary;
  final List<ItineraryStop> stops;
  final DateTime createdAt;

  const Itinerary({
    this.id,
    required this.userId,
    required this.title,
    required this.objective,
    required this.duration,
    this.status = 'verified',
    required this.summary,
    required this.stops,
    required this.createdAt,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json, [List<ItineraryStop>? stops]) {
    return Itinerary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Da Nang Adaptive Itinerary',
      objective: json['objective']?.toString() ?? 'culture',
      duration: json['duration']?.toString() ?? 'full_day',
      status: json['status']?.toString() ?? 'verified',
      summary: json['summary']?.toString() ?? '',
      stops: stops ?? (json['stops'] as List<dynamic>?)?.map((s) => ItineraryStop.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toItineraryMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'status': status,
    };
  }
}
