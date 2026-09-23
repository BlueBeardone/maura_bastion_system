import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';

Widget _harness(BastionTurnFacilityBuff buff) => MaterialApp(
      home: Scaffold(body: FacilityBuffCard(buff: buff)),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('starts collapsed: shows name and hirelings, not the benefit',
      (tester) async {
    await tester.pumpWidget(_harness(BastionTurnFacilityBuff(
      facility: Facility(
        id: 'f1',
        name: 'Training Area',
        rank: Rank.B,
        description: 'You gain one Trainer benefit.',
      ),
      hirelingCount: 4,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Training Area'), findsOneWidget);
    expect(find.text('Rank B'), findsOneWidget);
    expect(find.text('4 Hirelings'), findsOneWidget);
    expect(find.text('You gain one Trainer benefit.'), findsNothing);
  });

  testWidgets('expands on tap to reveal description, table and roll',
      (tester) async {
    await tester.pumpWidget(_harness(BastionTurnFacilityBuff(
      facility: Facility(
        id: 'f1',
        name: 'Training Area',
        rank: Rank.B,
        description: 'You gain one Trainer benefit.',
        table: FacilityTable(table: [
          ['Trainer', 'Benefit'],
          ['Weapon Expert', 'You gain +1 to hit with melee weapons.'],
        ]),
      ),
      hirelingCount: 4,
      rolledNumber: 1,
      rolledRow: '1 | Weapon Expert | You gain +1 to hit with melee weapons.',
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training Area'));
    await tester.pumpAndSettle();

    expect(find.text('You gain one Trainer benefit.'), findsOneWidget);
    expect(find.text('Rolled 1'), findsOneWidget);
    expect(
      find.text('1 | Weapon Expert | You gain +1 to hit with melee weapons.'),
      findsOneWidget,
    );
  });
}