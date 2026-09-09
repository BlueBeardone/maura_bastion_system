import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/quest_input_dialog.dart';

Future<void> pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => QuestInputDialog.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('shows Quest: title with a text field', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Quest:'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('confirm returns the trimmed typed text', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await QuestInputDialog.show(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Cleared the crypt  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, 'Cleared the crypt');
  });

  testWidgets('cancel returns null', (tester) async {
    String? result = 'sentinel';
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await QuestInputDialog.show(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('barrier dismissal returns null', (tester) async {
    String? result = 'sentinel';
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await QuestInputDialog.show(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the barrier above the route, outside the dialog.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('confirm is disabled for empty and whitespace-only input',
      (tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton confirmButton() =>
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Confirm'),
        );

    expect(confirmButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(confirmButton().onPressed, isNull);
  });
}
