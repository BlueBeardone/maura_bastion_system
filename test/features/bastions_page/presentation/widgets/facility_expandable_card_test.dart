import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_expandable_card.dart';

Facility _facility({String? table}) => Facility(
      id: 'cat_bedroom',
      name: 'Bedroom',
      rank: Rank.D,
      description:
          'If you long rest in your Bastion, gain 1d4 + Constitution Modifier as Max HP.',
      table: table == null
          ? null
          : FacilityTable(table: [
              ['d4', 'Effect'],
              ['1', 'Bonus flavor'],
            ]),
    );

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('collapsed card shows name and rank but no description',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [FacilityExpandableCard(facility: _facility())],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bedroom'), findsOneWidget);
    expect(find.text('Rank D'), findsOneWidget);
    expect(find.textContaining('long rest'), findsNothing);
  });

  testWidgets('tapping expands the card to show the full description and table',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            FacilityExpandableCard(facility: _facility(table: 't')),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('long rest in your Bastion'), findsOneWidget);
    expect(find.text('Bonus flavor'), findsOneWidget);
    expect(find.text('Open facility'), findsOneWidget);
  });

  testWidgets('Open facility invokes the callback', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            FacilityExpandableCard(
              facility: _facility(),
              onOpen: () => opened = true,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open facility'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('constructing facility dims and shows construction progress',
      (tester) async {
    final underConstruction = Facility(
      id: 'cat_barracks',
      name: 'Barracks',
      rank: Rank.D,
      description: 'Houses defenders.',
      constructionTurns: 2,
      constructedTurns: 1,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            FacilityExpandableCard(
              facility: underConstruction,
              hirelingCount: 2,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Construction: 1/2 turns'), findsOneWidget);
    expect(find.text('2 Hirelings'), findsOneWidget);

    // Opacity dimming
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Barracks'),
        matching: find.byType(Opacity),
      ).first,
    );
    expect(opacity.opacity, lessThan(1.0));
  });
}