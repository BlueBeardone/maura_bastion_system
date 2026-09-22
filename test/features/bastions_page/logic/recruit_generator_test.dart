import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/recruit_generator.dart';

ChartEvent _event(EventChart chart) => ChartEvent(
      id: 'evt_${chart.name}',
      name: 'Trial of ${chart.displayName}',
      chart: chart,
      tier: ChartTier.basic,
      description: 'desc',
    );

void main() {
  late RecruitGenerator generator;
  setUp(() => generator = RecruitGenerator(random: Random(7)));

  group('defenderTypeForChart', () {
    test('warMarch maps to knight', () {
      expect(RecruitGenerator.defenderTypeForChart(EventChart.warMarch),
          DefenderType.knight);
    });

    test('arcane and wilds map to beast', () {
      expect(RecruitGenerator.defenderTypeForChart(EventChart.arcane),
          DefenderType.beast);
      expect(RecruitGenerator.defenderTypeForChart(EventChart.wilds),
          DefenderType.beast);
    });

    test('deeps maps to bastion defender', () {
      expect(RecruitGenerator.defenderTypeForChart(EventChart.deeps),
          DefenderType.bastionDefender);
    });

    test('tradeRoad, hearth and null (archetype/uneventful) default to knight',
        () {
      expect(RecruitGenerator.defenderTypeForChart(EventChart.tradeRoad),
          DefenderType.knight);
      expect(RecruitGenerator.defenderTypeForChart(EventChart.hearth),
          DefenderType.knight);
      expect(RecruitGenerator.defenderTypeForChart(null), DefenderType.knight);
    });
  });

  test('generateDefender produces a name, mapped type and templated story',
      () {
    final recruit = generator.generateDefender(
      event: _event(EventChart.warMarch),
      bastionName: 'Maura Keep',
    );
    expect(recruit.defenderType, DefenderType.knight);
    expect(recruit.name, isNotEmpty);
    expect(recruit.role, isNull);
    expect(recruit.description, contains('Maura Keep'));
    expect(recruit.acquisitionStory, contains('Maura Keep'));
    expect(recruit.acquisitionStory, contains('Trial of The War March'));
  });

  test('generateHireling picks a role from the chart pool', () {
    final recruit = generator.generateHireling(
      event: _event(EventChart.hearth),
      bastionName: 'Maura Keep',
    );
    expect(recruit.role, anyOf('Cook', 'Steward', 'Servant', 'Chambermaid'));
    expect(recruit.defenderType, isNull);
    expect(recruit.acquisitionStory, contains('Trial of The Hearth'));
  });

  test('generateHireling falls back to the generic pool for other charts', () {
    final recruit = generator.generateHireling(
      event: _event(EventChart.wilds),
      bastionName: 'Maura Keep',
    );
    expect(recruit.role, anyOf('Laborer', 'Handler', 'Errand Runner', 'Groom'));
  });

  test('storyFor is reusable for the manual-path prefill', () {
    final story = generator.storyFor(
      event: _event(EventChart.deeps),
      bastionName: 'Maura Keep',
    );
    expect(story, contains('Trial of The Deeps'));
    expect(story, contains('Maura Keep'));
  });
}
