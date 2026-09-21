import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  test('single chart owns the whole 1-100 range', () {
    final slices = computeChartSlices({EventChart.wilds: 8});
    expect(slices.length, 1);
    expect(slices.single.rollMin, 1);
    expect(slices.single.rollMax, 100);
  });

  test('spec example 8/5/3 -> 1-50, 51-81, 82-100 (largest remainder)', () {
    final slices = computeChartSlices({
      EventChart.wilds: 8,
      EventChart.tradeRoad: 5,
      EventChart.hearth: 3,
    });
    expect(slices.map((s) => s.chart), [EventChart.wilds, EventChart.tradeRoad, EventChart.hearth]);
    expect(slices[0].rollMin, 1);
    expect(slices[0].rollMax, 50);
    expect(slices[1].rollMin, 51);
    expect(slices[1].rollMax, 81);
    expect(slices[2].rollMin, 82);
    expect(slices[2].rollMax, 100);
  });

  test('tie in points breaks by chart declaration order', () {
    final slices = computeChartSlices({EventChart.deeps: 8, EventChart.wilds: 8});
    expect(slices.map((s) => s.chart), [EventChart.wilds, EventChart.deeps]);
    expect(slices[0].rollMin, 1);
    expect(slices[0].rollMax, 50);
    expect(slices[1].rollMin, 51);
    expect(slices[1].rollMax, 100);
  });

  test('charts with zero or missing points get no slice', () {
    final slices = computeChartSlices({
      EventChart.wilds: 10,
      EventChart.hearth: 0,
    });
    expect(slices.map((s) => s.chart), [EventChart.wilds]);
  });

  test('slices are contiguous and cover 1-100', () {
    final slices = computeChartSlices({
      EventChart.wilds: 4,
      EventChart.deeps: 3,
      EventChart.tradeRoad: 3,
      EventChart.arcane: 2,
      EventChart.hearth: 4,
    });
    expect(slices.first.rollMin, 1);
    expect(slices.last.rollMax, 100);
    for (var i = 1; i < slices.length; i++) {
      expect(slices[i].rollMin, slices[i - 1].rollMax + 1);
    }
    for (final s in slices) {
      expect(s.rollMax - s.rollMin + 1, greaterThanOrEqualTo(1));
      expect(s.contains(s.rollMin), isTrue);
      expect(s.contains(s.rollMax), isTrue);
      expect(s.contains(s.rollMin - 1), isFalse);
      expect(s.contains(s.rollMax + 1), isFalse);
    }
  });

  test('ChartSlice value equality', () {
    final a = ChartSlice(
      chart: EventChart.wilds,
      points: 8,
      rollMin: 1,
      rollMax: 50,
    );
    final b = ChartSlice(
      chart: EventChart.wilds,
      points: 8,
      rollMin: 1,
      rollMax: 50,
    );
    final c = ChartSlice(
      chart: EventChart.wilds,
      points: 8,
      rollMin: 1,
      rollMax: 51,
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(equals(c)));
  });
}
