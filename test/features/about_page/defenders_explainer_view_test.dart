import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/features/about_page/defenders_explainer_view.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DefendersExplainerView()));
  }

  testWidgets('renders the three defender types', (tester) async {
    await pump(tester);
    expect(find.text('Knight'), findsOneWidget);
    expect(find.text('Bastion Defender'), findsOneWidget);
    expect(find.text('Beast'), findsOneWidget);
  });

  testWidgets('renders acquisition and defending sections', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('How to get defenders'), 500);
    await tester.scrollUntilVisible(find.text('Defending your Bastion'), 500);
    expect(find.text('Defending your Bastion'), findsOneWidget);
  });
}