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

    test('event result serializes rewardSummary', () {
      const result = BastionTurnEventResult(
        name: 'Wolf Cull',
        description: 'Wolves.',
        rewardSummary: '2 × Adamantine (Rank D)',
      );
      final json = result.toJson();
      expect(json['rewardSummary'], '2 × Adamantine (Rank D)');
      expect(
        BastionTurnEventResult.fromJson(json).rewardSummary,
        '2 × Adamantine (Rank D)',
      );
      const absent = BastionTurnEventResult(name: 'A', description: 'B');
      expect(absent.toJson()['rewardSummary'], isNull);
      expect(BastionTurnEventResult.fromJson(absent.toJson()).rewardSummary, isNull);
    });
  });

  group('facilityResults', () {
    test('round-trips populated list', () {
      const result = BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        facilityResults: [
          BastionTurnFacilityResult(
            name: 'Kitchen',
            rolledRow: '3 | Hearty meal | Everyone is fed',
          ),
          BastionTurnFacilityResult(name: 'Training Yard'),
        ],
      );
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.facilityResults.length, 2);
      expect(back.facilityResults[0].name, 'Kitchen');
      expect(back.facilityResults[0].rolledRow,
          '3 | Hearty meal | Everyone is fed');
      expect(back.facilityResults[1].name, 'Training Yard');
      expect(back.facilityResults[1].rolledRow, isNull);
    });

    test('defaults to empty and round-trips absent as empty', () {
      const result = BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
      );
      expect(result.facilityResults, isEmpty);
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.facilityResults, isEmpty);
    });
  });

  group('dispatch', () {
    test('event with dispatch round-trips', () {
      const event = BastionTurnEventResult(
        name: 'Wolf Cull',
        description: 'Wolves.',
        dispatch: BastionTurnDispatchResult(
          units: [
            BastionTurnDispatchUnitResult(
              name: 'Aldric',
              rolls: [4, 3],
              subtotal: 7,
            ),
          ],
          bonus: 2,
          total: 9,
          dc: 10,
          success: false,
        ),
      );
      final back = BastionTurnEventResult.fromJson(event.toJson());
      expect(back.dispatch, isNotNull);
      expect(back.dispatch!.units, hasLength(1));
      expect(back.dispatch!.units.first.name, 'Aldric');
      expect(back.dispatch!.units.first.rolls, [4, 3]);
      expect(back.dispatch!.units.first.subtotal, 7);
      expect(back.dispatch!.bonus, 2);
      expect(back.dispatch!.total, 9);
      expect(back.dispatch!.dc, 10);
      expect(back.dispatch!.success, isFalse);
      expect(event.toJson()['dispatch'], isA<Map<String, dynamic>>());
    });

    test('event without dispatch serializes dispatch as null', () {
      const event = BastionTurnEventResult(name: 'A', description: 'B');
      expect(event.toJson()['dispatch'], isNull);
      final back = BastionTurnEventResult.fromJson(event.toJson());
      expect(back.dispatch, isNull);
    });

    test('full BastionTurnResult round-trips dispatch inside event', () {
      const result = BastionTurnResult(
        bastionId: 'b',
        bastionName: 'n',
        quest: 'q',
        event: BastionTurnEventResult(
          name: 'Wolf Cull',
          description: 'Wolves.',
          dispatch: BastionTurnDispatchResult(
            units: [
              BastionTurnDispatchUnitResult(name: 'A', rolls: [1], subtotal: 1),
            ],
            bonus: 0,
            total: 5,
            dc: 5,
            success: true,
          ),
        ),
      );
      final back = BastionTurnResult.fromJson(result.toJson());
      expect(back.event?.dispatch?.success, isTrue);
    });
  });
}
