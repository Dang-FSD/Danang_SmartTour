class SafetyTicket {
  final int? id;
  final String userId;
  final int? dishId;
  final String? dishName;
  final String ticketCode;
  final String bilingualWarning;
  final String? dietaryWarningEn;
  final bool verified;
  final DateTime createdAt;

  const SafetyTicket({
    this.id,
    required this.userId,
    this.dishId,
    this.dishName,
    required this.ticketCode,
    required this.bilingualWarning,
    this.dietaryWarningEn,
    this.verified = false,
    required this.createdAt,
  });

  SafetyTicket copyWith({
    int? id,
    String? userId,
    int? dishId,
    String? dishName,
    String? ticketCode,
    String? bilingualWarning,
    String? dietaryWarningEn,
    bool? verified,
    DateTime? createdAt,
  }) {
    return SafetyTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      ticketCode: ticketCode ?? this.ticketCode,
      bilingualWarning: bilingualWarning ?? this.bilingualWarning,
      dietaryWarningEn: dietaryWarningEn ?? this.dietaryWarningEn,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SafetyTicket.fromJson(Map<String, dynamic> json) {
    return SafetyTicket(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id']?.toString() ?? '',
      dishId: json['dish_id'] != null ? int.tryParse(json['dish_id'].toString()) : null,
      dishName: json['dish_name']?.toString(),
      ticketCode: json['ticket_code']?.toString() ?? '',
      bilingualWarning: json['bilingual_warning']?.toString() ?? '',
      dietaryWarningEn: json['dietary_warning_en']?.toString(),
      verified: json['verified'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (dishId != null) 'dish_id': dishId,
      if (dishName != null) 'dish_name': dishName,
      'ticket_code': ticketCode,
      'bilingual_warning': bilingualWarning,
      if (dietaryWarningEn != null) 'dietary_warning_en': dietaryWarningEn,
      'verified': verified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
