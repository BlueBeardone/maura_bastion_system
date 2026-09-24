// test/features/bastions_page/presentation/widgets/animated_die_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/animated_die.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('settled die shows its value', (tester) async {
    await tester.pumpWidget(
      _wrap(const AnimatedDie(value: 4, faces: 6, rolling: false)),
    );
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('settled lethal value is drawn in vermillion', (tester) async {
    await tester.pumpWidget(
      _wrap(const AnimatedDie(value: 2, faces: 6, rolling: false, lethal: true)),
    );
    final text = tester.widget<Text>(find.text('2'));
    expect(text.style?.color, MedievalColors.vermillionDark);
  });

  testWidgets('rolling die cycles a face within range', (tester) async {
    await tester.pumpWidget(
      _wrap(const AnimatedDie(value: 3, faces: 6, rolling: true)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final text = tester.widget<Text>(find.byType(Text));
    expect(int.parse(text.data!), inInclusiveRange(1, 6));
  });
}
