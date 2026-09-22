import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/features/about_page/about_page.dart';
import 'package:maura_bastion_system/features/about_page/events_browser_view.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows themed content cards and debug section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    // The page header and the content card share the "Bastions" title.
    expect(find.text('Bastions'), findsNWidgets(2));
    expect(find.text('Construction Turns'), findsOneWidget);
    expect(find.textContaining('A Bastion is a player-owned stronghold built over time.'),
        findsOneWidget);
    // The ListView is lazy: scroll so the debug section is built.
    await tester.dragUntilVisible(
      find.text('How defenders work'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    // kDebugMode is true in tests, so the Developer section renders.
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Events browser'), findsOneWidget);
    expect(find.text('How defenders work'), findsOneWidget);
    expect(find.text('Theme reference'), findsOneWidget);
  });

  testWidgets('debug events tile navigates to the events browser', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.dragUntilVisible(
      find.text('Events browser'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Events browser'));
    await tester.pumpAndSettle();
    expect(find.byType(EventsBrowserView), findsOneWidget);
  });

  testWidgets('does not show rainbow accent card colors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, isNotEmpty);
    for (final card in cards) {
      expect(card.color, isNull, reason: 'cards must use the themed card color');
    }
  });
}
