// test/data/default_data/events/faction_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/faction_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

void main() {
  final events = factionEvents();

  test('has 12 unique events', () {
    expect(events.length, 12);
    expect(events.map((e) => e.id).toSet().length, 12);
  });

  test('every chart gains exactly one basic and one skilled event', () {
    for (final chart in EventChart.values) {
      final chartEvents = events.where((e) => e.chart == chart).toList();
      expect(chartEvents.length, 2, reason: chart.name);
      expect(
        chartEvents.where((e) => e.tier == ChartTier.basic).length,
        1,
        reason: chart.name,
      );
      expect(
        chartEvents.where((e) => e.tier == ChartTier.skilled).length,
        1,
        reason: chart.name,
      );
    }
  });

  test('each faction has three events', () {
    const factions = {
      'sc_': "Skeletor's Crew",
      'nan_': 'Nanoxy-chan',
      'twn_': 'The Twinsters',
      'wsp_': 'The Whispers',
    };
    for (final entry in factions.entries) {
      expect(
        events.where((e) => e.id.startsWith(entry.key)).length,
        3,
        reason: entry.value,
      );
    }
  });

  test("non-hearth events use only their chart's reward categories", () {
    for (final e in events) {
      final allowed = e.chart!.rewardCategories.toSet();
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
      if (e.reward.kind == RewardKind.material) {
        expect(e.reward.categories, isNotEmpty, reason: e.id);
      }
    }
  });

  test('hearth events are note-only', () {
    for (final e in events.where((e) => e.chart == EventChart.hearth)) {
      expect(e.reward.kind, RewardKind.none, reason: e.id);
      expect(e.reward.categories, isEmpty, reason: e.id);
      expect(e.reward.note, isNotNull, reason: e.id);
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
  });

  test('every event has a name, description, and reward note', () {
    for (final e in events) {
      expect(e.name.trim(), isNotEmpty, reason: e.id);
      expect(e.description.trim(), isNotEmpty, reason: e.id);
      expect(e.reward.note, isNotNull, reason: e.id);
    }
  });

  test('no faction event is an archetype or links a facility', () {
    for (final e in events) {
      expect(e.isArchetype, isFalse, reason: e.id);
      expect(e.facilityId, isNull, reason: e.id);
    }
  });
}
