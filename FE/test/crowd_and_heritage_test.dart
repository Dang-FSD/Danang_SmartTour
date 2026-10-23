import 'package:flutter_test/flutter_test.dart';
import 'package:danang_smarttour/data/models/heritage_guide_model.dart';
import 'package:danang_smarttour/data/models/safety_ticket_model.dart';

void main() {
  group('DaNang SmartTour AI — Heritage & Crowd Reroute Verification', () {
    test('Cham Museum Heritage Guide has verified strict sandstone protection rules', () {
      final guide = HeritageGuide.getGuideForAttraction(6);

      expect(guide.attractionId, equals(6));
      expect(guide.historicalEra.contains('Champa'), isTrue);
      expect(guide.highlights.contains('National Treasure Tara Bodhisattva'), isTrue);

      final strictRules = guide.etiquetteRules.where((r) => r.isStrict).toList();
      expect(strictRules.isNotEmpty, isTrue);
      expect(strictRules.any((r) => r.titleEn.contains('Touch Sandstone')), isTrue);
      expect(strictRules.any((r) => r.titleEn.contains('Flash')), isTrue);
    });

    test('Linh Ung Pagoda Heritage Guide enforces sacred modest dress code', () {
      final guide = HeritageGuide.getGuideForAttraction(7);

      expect(guide.attractionId, equals(7));
      expect(guide.highlights.any((h) => h.contains('67m')), isTrue);

      final dressCode = guide.etiquetteRules.firstWhere((r) => r.titleEn.contains('Dress Code'));
      expect(dressCode.isStrict, isTrue);
      expect(dressCode.descEn.contains('Shoulders and knees'), isTrue);
    });

    test('Non Nuoc Stone Village contributes directly to SDG 8 economic sustainability', () {
      final guide = HeritageGuide.getGuideForAttraction(3);

      expect(guide.attractionId, equals(3));
      expect(guide.sdgContribution.contains('SDG 8'), isTrue);
    });

    test('SafetyTicket with bilingualWarning and dietaryWarningEn serializes correctly', () {
      final ticket = SafetyTicket(
        id: 101,
        userId: '00000000-0000-0000-0000-000000000002',
        ticketCode: 'TKT-PEANUT-TEST',
        bilingualWarning: 'KHÁCH BỊ DỊ ỨNG ĐẬU PHỘNG NẶNG',
        dietaryWarningEn: 'Severe Peanut Allergy',
        verified: true,
        createdAt: DateTime.now(),
      );

      expect(ticket.verified, isTrue);
      expect(ticket.dietaryWarningEn, equals('Severe Peanut Allergy'));

      final json = ticket.toJson();
      expect(json['ticket_code'], equals('TKT-PEANUT-TEST'));
      expect(json['verified'], isTrue);
    });
  });
}
