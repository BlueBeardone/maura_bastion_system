import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';

void main() {
  testWidgets('renders the icon matching each defender type', (tester) async {
    final cases = {
      DefenderType.knight: Icons.shield,
      DefenderType.bastionDefender: Icons.castle,
      DefenderType.beast: Icons.pets,
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DefenderTypeIcon(type: entry.key)),
        ),
      );
      expect(find.byIcon(entry.value), findsOneWidget);
    }
  });
}
