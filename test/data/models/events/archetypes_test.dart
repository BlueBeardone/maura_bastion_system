import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/archetypes.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('convergence needs 4+ points in three different charts', () {
    expect(unlocksConvergence({EventChart.wilds: 4, EventChart.deeps: 4}), isFalse);
    expect(
        unlocksConvergence(
            {EventChart.wilds: 4, EventChart.deeps: 3, EventChart.hearth: 4}),
        isFalse);
    expect(
        unlocksConvergence(
            {EventChart.wilds: 4, EventChart.deeps: 4, EventChart.hearth: 4}),
        isTrue);
  });

  test('rivalry needs 8+ points in two different charts', () {
    expect(unlocksRivalry({EventChart.wilds: 8, EventChart.deeps: 7}), isFalse);
    expect(unlocksRivalry({EventChart.wilds: 8, EventChart.deeps: 8}), isTrue);
    expect(
        unlocksRivalry(
            {EventChart.wilds: 8, EventChart.deeps: 4, EventChart.hearth: 4}),
        isFalse);
  });

  test('missing charts count as zero points', () {
    expect(unlocksConvergence({EventChart.wilds: 16}), isFalse);
    expect(unlocksRivalry({EventChart.wilds: 16}), isFalse);
  });
}
