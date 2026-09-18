import 'package:maura_bastion_system/data/models/events/event_chart.dart';

/// Convergence events: 4+ points in three different charts.
bool unlocksConvergence(Map<EventChart, int> points) =>
    points.values.where((p) => p >= 4).length >= 3;

/// Rivalry events: 8+ points in two different charts (both Master tier — the
/// 16-point maximum allows exactly one such pairing).
bool unlocksRivalry(Map<EventChart, int> points) =>
    points.values.where((p) => p >= 8).length >= 2;
