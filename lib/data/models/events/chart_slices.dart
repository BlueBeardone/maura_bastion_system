// lib/data/models/events/chart_slices.dart
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

class ChartSlice {
  final EventChart chart;
  final int points;
  final int rollMin;
  final int rollMax;

  const ChartSlice({
    required this.chart,
    required this.points,
    required this.rollMin,
    required this.rollMax,
  });

  bool contains(int roll) => roll >= rollMin && roll <= rollMax;
}

/// Splits the 1d100 range across charts proportionally to their assigned
/// points, using largest-remainder rounding so the slices always sum to 100.
/// Charts with 0 points get no slice. Slices are ordered by points descending
/// (ties by chart declaration order).
List<ChartSlice> computeChartSlices(Map<EventChart, int> points) {
  final active = EventChart.values
      .where((c) => (points[c] ?? 0) > 0)
      .map((c) => (chart: c, points: points[c]!))
      .toList()
    ..sort((a, b) {
      if (a.points != b.points) return b.points.compareTo(a.points);
      return a.chart.index.compareTo(b.chart.index);
    });
  if (active.isEmpty) return const [];

  final total = active.fold<int>(0, (sum, a) => sum + a.points);
  final exact =
      active.map((a) => a.points * 100 / total).toList(growable: false);
  final sizes = exact.map((v) => v.floor()).toList();
  var leftover = 100 - sizes.fold<int>(0, (s, f) => s + f);

  final order = List<int>.generate(active.length, (i) => i)
    ..sort((a, b) {
      final ra = exact[a] - exact[a].floor();
      final rb = exact[b] - exact[b].floor();
      if (rb != ra) return rb.compareTo(ra);
      return a.compareTo(b);
    });
  for (var i = 0; leftover > 0 && i < order.length; i++, leftover--) {
    sizes[order[i]] += 1;
  }

  final slices = <ChartSlice>[];
  var next = 1;
  for (var i = 0; i < active.length; i++) {
    slices.add(ChartSlice(
      chart: active[i].chart,
      points: active[i].points,
      rollMin: next,
      rollMax: next + sizes[i] - 1,
    ));
    next += sizes[i];
  }
  return slices;
}
