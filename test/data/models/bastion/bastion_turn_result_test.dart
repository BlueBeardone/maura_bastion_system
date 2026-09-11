import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';

void main() {
  group('BastionTurnResult JSON round-trip', () {
    test('full payload round-trips', () {
      const result = BastionTurnResult(
        bastionId: 'bastion-1',
        bastionName: 'Ravencrest',
        quest: 'Clear the goblin warren',
        advancedFacility: BastionTurnAdvancedFacility(
          name: 'Kitchen',
          rankTitle: 'C',
          constructedTurns: 1,
          constructionTurns: 2,
        ),
        event: BastionTurnEventResult(
          name: 'Guest',
          description: 'A Notable guest arrives...',
          rolledRow: '2 | Seeking Sanctuary | They may stay for a turn',
        ),
      );
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.bastionId, 'bastion-1');
      expect(back.bastionName, 'Ravencrest');
      expect(back.quest, 'Clear the goblin warren');
      expect(back.advancedFacility?.name, 'Kitchen');
      expect(back.advancedFacility?.rankTitle, 'C');
      expect(back.advancedFacility?.constructedTurns, 1);
      expect(back.advancedFacility?.constructionTurns, 2);
      expect(back.event?.name, 'Guest');
      expect(back.event?.description, 'A Notable guest arrives...');
      expect(back.event?.rolledRow, '2 | Seeking Sanctuary | They may stay for a turn');
    });

    test('null optionals round-trip as null', () {
      const result = BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
      );
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.advancedFacility, isNull);
      expect(back.event, isNull);
      expect(back.event?.rolledRow, isNull);
    });

    test('event without rolledRow round-trips', () {
      const result = BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(name: 'Quiet Week', description: 'Nothing happens this turn.'),
      );
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.event?.name, 'Quiet Week');
      expect(back.event?.rolledRow, isNull);
    });
  });
}
