import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/utils/safe_network_image.dart';

void main() {
  const placeholderKey = Key('placeholder');

  Widget buildWidget(String? url) {
    return MaterialApp(
      home: Scaffold(
        body: SafeNetworkImage(
          url: url,
          placeholder: Container(key: placeholderKey),
          height: 100,
          width: 100,
        ),
      ),
    );
  }

  testWidgets('shows placeholder for null url', (tester) async {
    await tester.pumpWidget(buildWidget(null));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder for empty url', (tester) async {
    await tester.pumpWidget(buildWidget(''));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder for malformed url', (tester) async {
    await tester.pumpWidget(buildWidget('not-a-url'));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });

  testWidgets('shows placeholder when image fails to load', (tester) async {
    await tester.pumpWidget(buildWidget('https://127.0.0.1:1/broken.png'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(placeholderKey), findsOneWidget);
  });
}
