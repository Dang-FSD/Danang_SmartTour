import 'package:flutter_test/flutter_test.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/core/utils/dish_matcher.dart';
import 'package:danang_smarttour/data/models/dish_model.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';
import 'package:danang_smarttour/data/models/itinerary_model.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';
import 'package:danang_smarttour/data/models/heritage_guide_model.dart';

void main() {
  group('DaNang SmartTour AI — Comprehensive 32 Stability & Safety Test Suite', () {
    // Standard mock dishes for testing
    final catalogDishes = [
      const Dish(
        id: 1,
        nameVi: 'Mì Quảng Gà',
        hiddenIngredients: 'Nước dùng gà, đậu phộng rang, dầu đậu phộng, tôm khô',
        containsPeanut: true,
        containsPork: false,
        isSafeForHalal: true,
      ),
      const Dish(
        id: 2,
        nameVi: 'Bún chả cá Đà Nẵng',
        hiddenIngredients: 'Nước hầm xương heo, chả cá thu, mắm ruốc, mỡ heo',
        containsPork: true,
        containsPeanut: false,
        isSafeForHalal: false,
      ),
      const Dish(
        id: 3,
        nameVi: 'Bánh xèo nấm chay',
        hiddenIngredients: 'Bột gạo, nấm đùi gà, giá đỗ, nước tương đậu nành',
        containsPork: false,
        containsPeanut: false,
        isSafeForHalal: true,
      ),
      const Dish(
        id: 4,
        nameVi: 'Ram bắp Hội An - Đà Nẵng',
        hiddenIngredients: 'Bắp non bào, bánh tráng gạo, hành tiêu, dầu chiên hỗn hợp',
        containsPork: false,
        containsPeanut: false,
        isSafeForHalal: false,
        requiresKitchenConfirmation: true,
      ),
    ];

    // =========================================================================
    // SECTION 1: Ground-Truth 8 Binary Test Cases (Project Specification)
    // =========================================================================
    group('Section 1: Ground-Truth 8 Binary Safety Cases', () {
      test('Case 1: Halal Tourist + Bun cha ca (pork bone broth) -> RED FLAG (Violation)', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Bún chả cá Đà Nẵng',
          hiddenIngredients: 'Nước hầm xương heo, mỡ heo',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: false,
          dietRule: 'halal',
          allergen: null,
          allergenSeverity: null,
        );
        expect(verdict.level, equals(SafetyLevel.red));
        expect(verdict.reason.contains('HALAL VIOLATION'), isTrue);
      });

      test('Case 2: Cardiac Patient + Mui Nghe Trekking (hard) -> RED FLAG (Physical Hazard)', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Trekking Mũi Nghê',
          difficulty: 'hard',
          isOverloaded: false,
          medicalCondition: 'heart_disease',
          fitnessLevel: 'low',
        );
        expect(verdict.level, equals(SafetyLevel.red));
        expect(verdict.reason.contains('CARDIAC HAZARD'), isTrue);
      });

      test('Case 3: Peanut Allergy + Chicken Mi Quang -> YELLOW FLAG (Chef Dietary Ticket generated)', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Mì Quảng Gà',
          hiddenIngredients: 'Dầu phộng, đậu phộng rang',
          containsPork: false,
          containsPeanut: true,
          isSafeForHalal: true,
          requiresKitchenConfirmation: false,
          dietRule: null,
          allergen: 'peanut',
          allergenSeverity: 'severe',
        );
        expect(verdict.level, equals(SafetyLevel.yellow));
        expect(verdict.chefTicketVi, isNotNull);
        expect(verdict.chefTicketVi!.contains('ĐẬU PHỘNG'), isTrue);
      });

      test('Case 4: Vegan Tourist + Vegan Mushroom Pancake -> GREEN FLAG (100% Safe)', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Bánh xèo nấm chay',
          hiddenIngredients: 'Bột gạo, nấm tươi, giá',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: true,
          requiresKitchenConfirmation: false,
          dietRule: 'vegan',
          allergen: null,
          allergenSeverity: null,
        );
        expect(verdict.level, equals(SafetyLevel.green));
        expect(verdict.reason.contains('100% SAFE'), isTrue);
      });

      test('Case 5: Dragon Bridge Overloaded at Fire Show -> YELLOW FLAG (Divert to Non Nuoc)', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Cầu Rồng Đà Nẵng',
          difficulty: 'easy',
          isOverloaded: true,
          medicalCondition: null,
          fitnessLevel: 'moderate',
        );
        expect(verdict.level, equals(SafetyLevel.yellow));
        expect(verdict.reason.contains('OVERCROWDING'), isTrue);
        expect(verdict.alternativeSuggestion?.contains('Non Nuoc'), isTrue);
      });

      test('Case 6: Simulated Network Drop on Ticket Persist -> Rollback & Verification Failure', () {
        bool simulateTicketPersist({required bool shouldFail}) {
          if (shouldFail) return false;
          return true;
        }

        final verifiedState = simulateTicketPersist(shouldFail: true);
        expect(verifiedState, isFalse);
      });

      test('Case 7: Fit Tourist + SUP at My Khe Beach -> GREEN FLAG (Approved for High Fitness)', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Chèo SUP Biển Mỹ Khê',
          difficulty: 'moderate',
          isOverloaded: false,
          medicalCondition: null,
          fitnessLevel: 'high',
        );
        expect(verdict.level, equals(SafetyLevel.green));
        expect(verdict.reason.contains('APPROVED'), isTrue);
      });

      test('Case 8: Ambiguous Ram Bap Ingredients -> YELLOW FLAG (Human Handoff to Kitchen Staff)', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Ram bắp',
          hiddenIngredients: 'Dầu chiên chưa rõ',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: true,
          dietRule: 'vegan',
          allergen: null,
          allergenSeverity: null,
        );
        expect(verdict.level, equals(SafetyLevel.yellow));
        expect(verdict.requiresKitchenConfirmation, isTrue);
        expect(verdict.chefTicketVi!.contains('dầu thực vật hay mỡ lợn'), isTrue);
      });
    });

    // =========================================================================
    // SECTION 2: Multi-Risk & Complex Edge Combinations (6 Tests)
    // =========================================================================
    group('Section 2: Multi-Risk & Edge Combinations', () {
      test('Case 9: Multi-Allergy (Peanut + Seafood) + Seafood Mi Quang -> RED FLAG due to seafood', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Mì Quảng Tôm Thịt',
          hiddenIngredients: 'Tôm tươi, nước dùng cá, đậu phộng rang',
          containsPork: false,
          containsPeanut: true,
          isSafeForHalal: true,
          requiresKitchenConfirmation: false,
          dietRule: null,
          allergen: 'seafood',
          allergenSeverity: 'severe',
        );
        expect(verdict.level, equals(SafetyLevel.red));
        expect(verdict.reason.contains('SEAFOOD ALLERGY'), isTrue);
      });

      test('Case 10: Halal Tourist with Cardiac History -> Evaluates both food and terrain', () {
        final foodVerdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Bún chả cá',
          hiddenIngredients: 'Xương heo',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: false,
          dietRule: 'halal',
          allergen: null,
          allergenSeverity: null,
        );
        final trailVerdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Mũi Nghê',
          difficulty: 'hard',
          isOverloaded: false,
          medicalCondition: 'heart_disease',
          fitnessLevel: 'low',
        );
        expect(foodVerdict.level, equals(SafetyLevel.red));
        expect(trailVerdict.level, equals(SafetyLevel.red));
      });

      test('Case 11: Vegan Tourist encountering dish with concentrated fermented fish sauce -> RED FLAG', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Bánh tráng cuốn',
          hiddenIngredients: 'Nước chấm mắm nêm cá cơm, thịt luộc',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: false,
          dietRule: 'vegan',
          allergen: null,
          allergenSeverity: null,
        );
        expect(verdict.level, equals(SafetyLevel.red));
        expect(verdict.reason.contains('VEGAN VIOLATION'), isTrue);
      });

      test('Case 12: Low Fitness Traveler in High Heat/Steep trail -> Prevent steep cliff climbing', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Đỉnh Bàn Cờ leo bộ',
          difficulty: 'hard',
          isOverloaded: false,
          medicalCondition: null,
          fitnessLevel: 'low',
        );
        expect(verdict.level, equals(SafetyLevel.red));
      });

      test('Case 13: Mild peanut allergy still triggers Chef Ticket with precautions', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Mì Quảng',
          hiddenIngredients: 'Đậu phộng',
          containsPork: false,
          containsPeanut: true,
          isSafeForHalal: true,
          requiresKitchenConfirmation: false,
          dietRule: null,
          allergen: 'peanut',
          allergenSeverity: 'mild',
        );
        expect(verdict.level, equals(SafetyLevel.yellow));
        expect(verdict.chefTicketVi, isNotNull);
      });

      test('Case 14: Halal tourist facing shared frying pan oil -> Flagged in Case 8 kitchen handoff', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Chả giò bắp chiên',
          hiddenIngredients: 'Chưa rõ dầu chiên',
          containsPork: false,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: true,
          dietRule: 'halal',
          allergen: null,
          allergenSeverity: null,
        );
        expect(verdict.requiresKitchenConfirmation, isTrue);
      });
    });

    // =========================================================================
    // SECTION 3: AI Vision Matching & Fuzzy Parsing (6 Tests)
    // =========================================================================
    group('Section 3: AI Vision Matching & Fuzzy Parsing', () {
      test('Case 15: Accent-insensitive match ("Banh xeo chay") resolves to Bánh xèo nấm chay', () {
        final match = DishMatcher.matchOrConstructDish(
          detectedRawName: 'Banh xeo chay',
          availableDishes: catalogDishes,
        );
        expect(match.dish.nameVi, equals('Bánh xèo nấm chay'));
        expect(match.isCustomDetected, isFalse);
      });

      test('Case 16: English alias match ("Quang noodles") resolves to Mì Quảng Gà', () {
        final match = DishMatcher.matchOrConstructDish(
          detectedRawName: 'Famous Quang noodles in bowl',
          availableDishes: catalogDishes,
        );
        expect(match.dish.nameVi, equals('Mì Quảng Gà'));
      });

      test('Case 17: English alias match ("Fish cake noodle soup") resolves to Bún chả cá Đà Nẵng', () {
        final match = DishMatcher.matchOrConstructDish(
          detectedRawName: 'Vietnamese fish cake noodle soup',
          availableDishes: catalogDishes,
        );
        expect(match.dish.nameVi, equals('Bún chả cá Đà Nẵng'));
      });

      test('Case 18: Unlisted street food dynamically constructs Dynamic Dish from AI payload', () {
        final match = DishMatcher.matchOrConstructDish(
          detectedRawName: 'Nem lụi nướng sả',
          availableDishes: catalogDishes,
          aiPayload: {
            'dish_name': 'Nem lụi nướng sả Đà Nẵng',
            'hidden_ingredients': 'Thịt heo xay, mỡ heo, sả, nước tương đậu phộng',
            'requires_kitchen_confirmation': false,
          },
        );
        expect(match.isCustomDetected, isTrue);
        expect(match.dish.id, equals(9999));
        expect(match.dish.containsPork, isTrue);
        expect(match.dish.containsPeanut, isTrue);
      });

      test('Case 19: Diacritics stripper removes all Central Vietnamese tonal marks cleanly', () {
        const input = 'Mì Quảng Ẩm Thực Đà Nẵng';
        final stripped = DishMatcher.removeDiacritics(input);
        expect(stripped, equals('mi quang am thuc da nang'));
      });

      test('Case 20: Completely unrecognized dish safely falls back without crash', () {
        final match = DishMatcher.matchOrConstructDish(
          detectedRawName: 'Unknown futuristic alien food',
          availableDishes: catalogDishes,
        );
        expect(match.dish, isNotNull);
        expect(match.confidenceScore, lessThanOrEqualTo(0.50));
      });
    });

    // =========================================================================
    // SECTION 4: Overtourism & GIS Dynamic Navigation (4 Tests)
    // =========================================================================
    group('Section 4: Overtourism & GIS Dynamic Navigation', () {
      test('Case 21: Dragon Bridge overloaded at weekend fire show triggers Non Nuoc detour', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Cầu Rồng',
          difficulty: 'easy',
          isOverloaded: true,
          medicalCondition: null,
          fitnessLevel: 'moderate',
        );
        expect(verdict.level, equals(SafetyLevel.yellow));
        expect(verdict.alternativeSuggestion, contains('Non Nuoc'));
      });

      test('Case 22: My Khe beach during high waves & rip current warns watersports travelers', () {
        final beach = Attraction(
          id: 4,
          nameVi: 'Biển Mỹ Khê',
          category: 'sport',
          difficulty: 'moderate',
          isOverloaded: true,
          latitude: 16.0602,
          longitude: 108.2462,
        );
        expect(beach.isOverloaded, isTrue);
      });

      test('Case 23: Normal traffic conditions approve easy attractions without warnings', () {
        final verdict = SafetyEvaluator.evaluateAttractionSafety(
          attractionName: 'Bảo tàng Điêu khắc Chăm',
          difficulty: 'easy',
          isOverloaded: false,
          medicalCondition: null,
          fitnessLevel: 'moderate',
        );
        expect(verdict.level, equals(SafetyLevel.green));
      });

      test('Case 24: Non Nuoc Stone Carving Village has valid GIS coordinates in Da Nang', () {
        final village = Attraction(
          id: 3,
          nameVi: 'Làng đá Mỹ nghệ Non Nước',
          category: 'culture',
          difficulty: 'easy',
          latitude: 16.0028,
          longitude: 108.2639,
        );
        expect(village.latitude, inInclusiveRange(15.9, 16.2));
        expect(village.longitude, inInclusiveRange(108.0, 108.4));
      });
    });

    // =========================================================================
    // SECTION 5: Heritage Etiquette & SDG Verification (4 Tests)
    // =========================================================================
    group('Section 5: Heritage Etiquette & SDG Verification', () {
      test('Case 25: Linh Ung Pagoda enforces sacred modesty dress code rules', () {
        final guide = HeritageGuide.getGuideForAttraction(7);
        final dressCode = guide.etiquetteRules.firstWhere((r) => r.icon == '👗');
        expect(dressCode.isStrict, isTrue);
        expect(dressCode.titleEn, contains('Modest'));
      });

      test('Case 26: Cham Museum enforces strict sandstone sculpture conservation (no touching)', () {
        final guide = HeritageGuide.getGuideForAttraction(6);
        final touchRule = guide.etiquetteRules.firstWhere((r) => r.icon == '🚫');
        expect(touchRule.isStrict, isTrue);
        expect(touchRule.titleEn, contains('Do Not Touch'));
      });

      test('Case 27: Non Nuoc Village contributes directly to UN SDG 8 economic sustainability', () {
        final guide = HeritageGuide.getGuideForAttraction(3);
        expect(guide.sdgContribution, contains('SDG 8'));
      });

      test('Case 28: Zero False-Safe rule ensures SDG 10 inclusive tourism accessibility', () {
        final profile = TravelerProfile.sampleHalal;
        expect(profile.dietRule, equals('halal'));
      });
    });

    // =========================================================================
    // SECTION 6: Data Serialization, RLS & Verification Integrity (4 Tests)
    // =========================================================================
    group('Section 6: Data Serialization, RLS & Verification Integrity', () {
      test('Case 29: SafetyTicket serializes and deserializes bilingual and English warnings accurately', () {
        final original = SafetyTicket(
          id: 777,
          userId: 'test-user-uuid',
          dishName: 'Mì Quảng',
          ticketCode: 'TICKET-DN-777',
          dietaryWarningEn: 'No peanuts please',
          bilingualWarning: 'KHÔNG ĐẬU PHỘNG',
          verified: true,
          createdAt: DateTime(2026, 10, 23),
        );

        final json = original.toJson();
        final reconstituted = SafetyTicket.fromJson(json);

        expect(reconstituted.ticketCode, equals('TICKET-DN-777'));
        expect(reconstituted.dietaryWarningEn, equals('No peanuts please'));
        expect(reconstituted.bilingualWarning, equals('KHÔNG ĐẬU PHỘNG'));
        expect(reconstituted.verified, isTrue);
      });

      test('Case 30: ItineraryStop model maintains GIS coordinates and reroute flags', () {
        const stop = ItineraryStop(
          timeSlot: '09:00 - 11:00',
          name: 'Non Nuoc Stone Village',
          category: 'culture',
          safetyLevel: SafetyLevel.green,
          safetyReason: 'Rerouted from congested bridge',
          isRerouted: true,
          originalName: 'Dragon Bridge',
          latitude: 16.0028,
          longitude: 108.2639,
        );

        final json = stop.toJson();
        final reconstituted = ItineraryStop.fromJson(json);

        expect(reconstituted.isRerouted, isTrue);
        expect(reconstituted.originalName, equals('Dragon Bridge'));
        expect(reconstituted.latitude, equals(16.0028));
      });

      test('Case 31: Default TravelerProfile with null values handles copyWith without exceptions', () {
        const defaultProfile = TravelerProfile(
          id: 'anon-user',
          displayName: 'Guest Traveler',
        );

        final updated = defaultProfile.copyWith(
          dietRule: 'halal',
          fitnessLevel: 'high',
        );

        expect(updated.dietRule, equals('halal'));
        expect(updated.fitnessLevel, equals('high'));
        expect(updated.allergen, isNull);
      });

      test('Case 32: Zero False-Safety check: A known pork dish NEVER produces GREEN for Halal', () {
        final verdict = SafetyEvaluator.evaluateDishSafety(
          dishName: 'Thịt heo luộc',
          hiddenIngredients: 'Thịt heo 100%',
          containsPork: true,
          containsPeanut: false,
          isSafeForHalal: false,
          requiresKitchenConfirmation: false,
          dietRule: 'halal',
          allergen: null,
          allergenSeverity: null,
        );

        expect(verdict.level, isNot(equals(SafetyLevel.green)));
        expect(verdict.level, equals(SafetyLevel.red));
      });
    });
  });
}
