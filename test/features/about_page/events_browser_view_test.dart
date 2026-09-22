import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/features/about_page/events_browser_view.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: EventsBrowserView()));
  }

  testWidgets('renders section headers and explainers', (tester) async {
    await pump(tester);
    expect(find.text('Individual Bastion Events (d100)'), findsOneWidget);
    expect(
      find.textContaining('roll 1d100', findRichText: true),
      findsWidgets,
    );
    await tester.scrollUntilVisible(find.text('Chart events'), 800);
    expect(find.text('Chart events'), findsOneWidget);
  });

  testWidgets('renders individual bastion events with roll ranges', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('Duel'), 400);
    expect(find.text('Duel'), findsOneWidget);
    expect(find.text('66–68'), findsOneWidget);
  });

  testWidgets('renders chart events grouped by chart', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('The Wilds'), 600);
    await tester.scrollUntilVisible(find.text('Foraging Party'), 400);
    expect(find.text('Foraging Party'), findsOneWidget);
    expect(find.textContaining('Reward:'), findsWidgets);
  });

  testWidgets('renders embedded tables for events that have one', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('# of Attackers per Rank above D'), 600);
    expect(find.textContaining('Attackers'), findsWidgets);
  });
}
