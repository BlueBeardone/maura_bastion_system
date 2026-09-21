import 'dart:math';

import 'package:maura_bastion_system/data/models/events/event_chart.dart';

class ChartPoints {
  static const int maxPoints = 16;

  final Map<EventChart, int> points;
  final int earnedPoints;

  const ChartPoints({this.points = const {}, required this.earnedPoints});

  int get assignedTotal => points.values.fold(0, (sum, p) => sum + p);

  int get unassigned => earnedPoints - assignedTotal;

  int operator [](EventChart chart) => points[chart] ?? 0;

  bool canAssign(EventChart chart, int delta) {
    if (this[chart] + delta < 0) return false;
    final nextTotal = assignedTotal + delta;
    return nextTotal >= 0 &&
        nextTotal <= earnedPoints &&
        nextTotal <= maxPoints;
  }

  ChartPoints assign(EventChart chart, int delta) {
    if (!canAssign(chart, delta)) return this;
    final updated = Map<EventChart, int>.from(points)
      ..[chart] = this[chart] + delta;
    return ChartPoints(points: updated, earnedPoints: earnedPoints);
  }

  Map<EventChart, int> randomizedAllocation({Random? rng}) {
    final random = rng ?? Random();
    final effective = Map<EventChart, int>.from(points);
    var remaining = unassigned;
    while (remaining > 0) {
      final chart = EventChart.values[random.nextInt(EventChart.values.length)];
      effective[chart] = (effective[chart] ?? 0) + 1;
      remaining--;
    }
    return effective;
  }
}
