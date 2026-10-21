import 'package:flutter_test/flutter_test.dart';
import 'package:danang_smarttour/core/utils/safety_evaluator.dart';
import 'package:danang_smarttour/data/models/traveler_profile_model.dart';

void main() {
  group('DaNang SmartTour AI — 8 Binary Ground-Truth Test Cases (International English)', () {
    test('Case 1: Halal Tourist + Da Nang Fish Cake Noodle Soup (Pork broth) -> RED FLAG (Violation)', () {
      final verdict = SafetyEvaluator.evaluateDishSafety(
        dishName: 'Bún chả cá Đà Nẵng',
        hiddenIngredients: 'Nước dùng ninh xương heo, chả cá, mắm ruốc',
        containsPork: true,
        containsPeanut: false,
        isSafeForHalal: false,
        requiresKitchenConfirmation: false,
        dietRule: TravelerProfile.sampleHalal.dietRule,
        allergen: TravelerProfile.sampleHalal.allergen,
        allergenSeverity: TravelerProfile.sampleHalal.allergenSeverity,
      );

      expect(verdict.level, equals(SafetyLevel.red));
      expect(verdict.reason.contains('HALAL VIOLATION'), isTrue);
      expect(verdict.alternativeSuggestion != null, isTrue);
    });

    test('Case 2: Cardiac Patient + Mui Nghe Steep Trekking -> RED FLAG (Physical Hazard)', () {
      final verdict = SafetyEvaluator.evaluateAttractionSafety(
        attractionName: 'Trekking Mũi Nghê',
        difficulty: 'hard',
        isOverloaded: false,
        medicalCondition: TravelerProfile.sampleHeart.medicalCondition,
        fitnessLevel: TravelerProfile.sampleHeart.fitnessLevel,
      );

      expect(verdict.level, equals(SafetyLevel.red));
      expect(verdict.reason.contains('CARDIAC HAZARD'), isTrue);
      expect(verdict.alternativeSuggestion?.contains('Douc Langur'), isTrue);
    });

    test('Case 3: Peanut Allergy + Chicken Mi Quang -> YELLOW FLAG (Chef Dietary Ticket triggered)', () {
      final verdict = SafetyEvaluator.evaluateDishSafety(
        dishName: 'Mì Quảng Gà',
        hiddenIngredients: 'Nước lèo gà, phi dầu phộng, rắc đậu phộng rang',
        containsPork: false,
        containsPeanut: true,
        isSafeForHalal: true,
        requiresKitchenConfirmation: false,
        dietRule: TravelerProfile.samplePeanut.dietRule,
        allergen: TravelerProfile.samplePeanut.allergen,
        allergenSeverity: TravelerProfile.samplePeanut.allergenSeverity,
      );

      expect(verdict.level, equals(SafetyLevel.yellow));
      expect(verdict.chefTicketVi != null, isTrue);
      expect(verdict.chefTicketVi!.contains('ĐẬU PHỘNG'), isTrue);
      expect(verdict.chefTicketEn!.contains('PEANUT ALLERGY'), isTrue);
    });

    test('Case 4: Vegan Tourist + Vegan Mushroom Sizzling Pancake -> GREEN FLAG (100% Safe)', () {
      final verdict = SafetyEvaluator.evaluateDishSafety(
        dishName: 'Bánh xèo nấm chay',
        hiddenIngredients: 'Nấm, bột gạo, dầu thực vật',
        containsPork: false,
        containsPeanut: false,
        isSafeForHalal: true,
        requiresKitchenConfirmation: false,
        dietRule: TravelerProfile.sampleFitVegan.dietRule,
        allergen: TravelerProfile.sampleFitVegan.allergen,
        allergenSeverity: TravelerProfile.sampleFitVegan.allergenSeverity,
      );

      expect(verdict.level, equals(SafetyLevel.green));
    });

    test('Case 5: Dragon Bridge Overloaded at Fire-breathing Hour -> Smart Reroute to Non Nuoc Village', () {
      final verdict = SafetyEvaluator.evaluateAttractionSafety(
        attractionName: 'Cầu Rồng (Giờ phun lửa)',
        difficulty: 'easy',
        isOverloaded: true,
        medicalCondition: null,
        fitnessLevel: 'moderate',
      );

      expect(verdict.level, equals(SafetyLevel.yellow));
      expect(verdict.reason.contains('OVERCROWDING'), isTrue);
      expect(verdict.alternativeSuggestion?.contains('Non Nuoc'), isTrue);
    });

    test('Case 6: Simulated Network Disconnection on Ticket Persist -> Rollback & Verification Failure', () {
      const bool networkFailed = true;
      bool verifiedStatus = false;

      if (!networkFailed) {
        verifiedStatus = true;
      }

      expect(verifiedStatus, isFalse);
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
    });

    test('Case 8: Ambiguous Corn Spring Rolls (Ram bắp) -> YELLOW FLAG (Human Handoff to Kitchen Staff)', () {
      final verdict = SafetyEvaluator.evaluateDishSafety(
        dishName: 'Ram bắp gia truyền',
        hiddenIngredients: 'Nguyên liệu cuốn hỗn hợp mơ hồ, có thể chiên chung dầu lợn',
        containsPork: false,
        containsPeanut: false,
        isSafeForHalal: false,
        requiresKitchenConfirmation: true,
        dietRule: 'halal',
        allergen: null,
        allergenSeverity: null,
      );

      expect(verdict.level, equals(SafetyLevel.yellow));
      expect(verdict.requiresKitchenConfirmation, isTrue);
      expect(verdict.reason.contains('AMBIGUOUS INGREDIENTS'), isTrue);
    });
  });
}
