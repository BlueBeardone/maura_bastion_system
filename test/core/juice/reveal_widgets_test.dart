import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';

void main() {
  testWidgets('StampIn settles to fully visible child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: StampIn(child: Text('stamped')))),
    ));
    expect(find.text('stamped'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('stamped'), findsOneWidget);
  });

  testWidgets('StampIn respects reduced motion (visible immediately)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: StampIn(
              delay: Duration(seconds: 5),
              child: Text('stamped'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1.0);
  });

  testWidgets('FadeSlide settles and stays mounted', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FadeSlide(child: Text('slid')))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('slid'), findsOneWidget);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1.0);
  });

  testWidgets('Shake shakes on trigger edge and settles back', (tester) async {
    var trigger = false;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: Center(
            child: Column(children: [
              Shake(trigger: trigger, child: const Text('dice')),
              TextButton(
                onPressed: () => setState(() => trigger = true),
                child: const Text('go'),
              ),
            ]),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('dice'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('dice'), findsOneWidget);
  });

  testWidgets('SparkleOverlay burst runs and settles without errors',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SparkleOverlay(auto: true, child: Text('reward')),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('reward'), findsOneWidget);
  });

  testWidgets('SparkleBurst.show inserts and removes an overlay burst',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => SparkleBurst.show(context),
              child: const Text('pay'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('pay'));
    await tester.pump();
    expect(find.byType(SparkleBurstView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(SparkleBurstView), findsNothing);
  });
}
