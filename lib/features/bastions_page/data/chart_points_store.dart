import 'dart:convert';

import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChartPointsStore {
  static const _prefix = 'chart_points_';

  Future<void> save(String bastionId, ChartPoints points) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'points': {
        for (final entry in points.points.entries)
          if (entry.value > 0) entry.key.name: entry.value,
      },
    });
    await prefs.setString('$_prefix$bastionId', json);
  }

  Future<Map<EventChart, int>> read(String bastionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bastionId');
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final points = decoded['points'] as Map<String, dynamic>? ?? {};
      return {
        for (final entry in points.entries)
          if (EventChart.values.where((c) => c.name == entry.key).isNotEmpty)
            EventChart.values.firstWhere((c) => c.name == entry.key):
                (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }
}
