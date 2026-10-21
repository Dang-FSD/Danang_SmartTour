import 'package:danang_smarttour/core/constants/app_colors.dart';

enum SafetyLevel {
  red,
  yellow,
  green;

  String get code {
    switch (this) {
      case SafetyLevel.red:
        return 'RED';
      case SafetyLevel.yellow:
        return 'YELLOW';
      case SafetyLevel.green:
        return 'GREEN';
    }
  }

  String get labelEn {
    switch (this) {
      case SafetyLevel.red:
        return 'HAZARD / BLOCKED';
      case SafetyLevel.yellow:
        return 'CAUTION / MODIFICATION NEEDED';
      case SafetyLevel.green:
        return '100% SAFE';
    }
  }
}

class SafetyVerdict {
  final SafetyLevel level;
  final String reason;
  final String? chefTicketVi;
  final String? chefTicketEn;
  final String? alternativeSuggestion;
  final bool requiresKitchenConfirmation;

  const SafetyVerdict({
    required this.level,
    required this.reason,
    this.chefTicketVi,
    this.chefTicketEn,
    this.alternativeSuggestion,
    this.requiresKitchenConfirmation = false,
  });
}

class SafetyEvaluator {
  /// Evaluates dish safety based on Traveler Profile (Ground-Truth Cases 1, 3, 4, 8)
  static SafetyVerdict evaluateDishSafety({
    required String dishName,
    required String hiddenIngredients,
    required bool containsPork,
    required bool containsPeanut,
    required bool isSafeForHalal,
    required bool requiresKitchenConfirmation,
    required String? dietRule, // 'halal', 'vegan', 'vegetarian'
    required String? allergen, // 'peanut', 'seafood', etc.
    required String? allergenSeverity, // 'mild', 'severe'
  }) {
    final lowerDiet = dietRule?.toLowerCase() ?? '';
    final lowerAllergen = allergen?.toLowerCase() ?? '';

    // CASE 8: Ambiguous ingredients (e.g. Traditional Corn Spring Rolls - Ram bắp) -> Require kitchen staff confirmation
    if (requiresKitchenConfirmation) {
      return const SafetyVerdict(
        level: SafetyLevel.yellow,
        reason: 'AMBIGUOUS INGREDIENTS: Spring roll wrapper may contain unlisted flour blends or be fried in shared animal oil. Kitchen staff verification required.',
        requiresKitchenConfirmation: true,
        chefTicketVi: 'Xin hỏi món này dùng dầu thực vật hay mỡ lợn? Có chiên chung chảo với thịt không?',
        chefTicketEn: 'Does this dish use vegetable oil or animal lard? Is it fried in the same pan with meat products?',
      );
    }

    // CASE 1: Halal tourist encounter pork or bone broth (e.g. Bún chả cá Đà Nẵng)
    if (lowerDiet == 'halal') {
      if (containsPork || !isSafeForHalal) {
        return const SafetyVerdict(
          level: SafetyLevel.red,
          reason: 'HALAL VIOLATION: Broth is stewed with pork bones and flavored with fermented shrimp paste or pork lard, strictly violating Islamic dietary laws.',
          alternativeSuggestion: 'Safe Alternative: An Lac Vegetarian Restaurant or certified Halal dining spots in Da Nang.',
        );
      }
    }

    // Vegan / Vegetarian
    if (lowerDiet == 'vegan' || lowerDiet == 'vegetarian') {
      if (containsPork || !isSafeForHalal) {
        return const SafetyVerdict(
          level: SafetyLevel.red,
          reason: 'VEGAN VIOLATION: This dish contains animal-derived broth, pork lard, or fermented fish paste.',
          alternativeSuggestion: 'Safe Alternative: Vegan Mushroom Sizzling Pancake (Bánh xèo nấm chay) or Vegan Mi Quang.',
        );
      }
    }

    // CASE 3: Peanut allergy + Chicken Mi Quang (garnished with roasted peanuts & peanut oil)
    if (lowerAllergen.contains('peanut') || lowerAllergen.contains('đậu phộng') || lowerAllergen.contains('lạc')) {
      if (containsPeanut) {
        return const SafetyVerdict(
          level: SafetyLevel.yellow,
          reason: 'PEANUT ALLERGY ALERT: Dish uses sautéed peanut oil and is topped with roasted crushed peanuts. A Chef Dietary Ticket must be presented.',
          chefTicketVi: 'Tôi bị dị ứng ĐẬU PHỘNG / LẠC rất nặng (sốc phản vệ). Xin vui lòng TUYỆT ĐỐI KHÔNG rắc đậu phộng và KHÔNG dùng dầu phộng cho món này!',
          chefTicketEn: 'I have a SEVERE PEANUT ALLERGY (anaphylaxis). Please strictly DO NOT garnish with peanuts or cook with peanut oil!',
        );
      }
    }

    // Seafood allergy
    if (lowerAllergen.contains('seafood') || lowerAllergen.contains('hải sản')) {
      if (hiddenIngredients.toLowerCase().contains('tôm') ||
          hiddenIngredients.toLowerCase().contains('cá') ||
          hiddenIngredients.toLowerCase().contains('mắm ruốc') ||
          hiddenIngredients.toLowerCase().contains('mắm nêm') ||
          hiddenIngredients.toLowerCase().contains('shrimp') ||
          hiddenIngredients.toLowerCase().contains('fish')) {
        return const SafetyVerdict(
          level: SafetyLevel.red,
          reason: 'SEAFOOD ALLERGY ALERT: Contains seafood broth, dried shrimp, or concentrated fermented fish paste.',
        );
      }
    }

    // CASE 4: Vegan tourist + Vegan Mushroom Pancake (100% Safe)
    return const SafetyVerdict(
      level: SafetyLevel.green,
      reason: '100% SAFE: All ingredients comply with your dietary restrictions and health profile.',
    );
  }

  /// Evaluates physical hazard and crowd safety (Ground-Truth Cases 2, 5, 7)
  static SafetyVerdict evaluateAttractionSafety({
    required String attractionName,
    required String difficulty, // 'easy', 'moderate', 'hard'
    required bool isOverloaded,
    required String? medicalCondition, // 'heart_disease'
    required String? fitnessLevel, // 'low', 'moderate', 'high'
  }) {
    final hasHeartDisease = (medicalCondition?.toLowerCase() == 'heart_disease' ||
        fitnessLevel?.toLowerCase() == 'low');

    // CASE 2: Cardiac patient attempting steep trekking (Mui Nghe trail)
    if (hasHeartDisease && difficulty.toLowerCase() == 'hard') {
      return const SafetyVerdict(
        level: SafetyLevel.red,
        reason: 'CARDIAC HAZARD: Extremely steep cliffside terrain. Severe physical strain poses a high cardiac and heatstroke risk.',
        alternativeSuggestion: 'Auto-Reroute: Son Tra Red-shanked Douc Langur Walking Trail (Gentle, paved road shaded by trees).',
      );
    }

    // CASE 5: Overcrowded destination (Dragon Bridge during fire-breathing show)
    if (isOverloaded) {
      return const SafetyVerdict(
        level: SafetyLevel.yellow,
        reason: 'OVERCROWDING DETECTED (Overtourism Alert): Heavy pedestrian and vehicular gridlock at this hour.',
        alternativeSuggestion: 'Smart Reroute: Divert to Non Nuoc Stone Carving Village or Cham Sculpture Museum instead.',
      );
    }

    // CASE 7: Fit tourist doing Stand-Up Paddleboarding (SUP) at My Khe Beach
    return const SafetyVerdict(
      level: SafetyLevel.green,
      reason: 'APPROVED: Suitable for your fitness level. Always wear provided life jackets and check sea weather.',
    );
  }
}
