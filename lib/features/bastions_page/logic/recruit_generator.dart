import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defender_name_generator.dart';

class GeneratedRecruit {
  final String name;
  final DefenderType? defenderType;
  final String? role;
  final String description;
  final String acquisitionStory;

  const GeneratedRecruit({
    required this.name,
    this.defenderType,
    this.role,
    required this.description,
    required this.acquisitionStory,
  });
}

class RecruitGenerator {
  RecruitGenerator({Random? random})
      : _random = random ?? Random(),
        _names = DefenderNameGenerator(random: random);

  final Random _random;
  final DefenderNameGenerator _names;

  static const _rolesByChart = <EventChart, List<String>>{
    EventChart.tradeRoad: ['Factor', 'Caravan Agent', 'Courier', 'Merchant Scribe'],
    EventChart.hearth: ['Cook', 'Steward', 'Servant', 'Chambermaid'],
  };

  static const _fallbackRoles = ['Laborer', 'Handler', 'Errand Runner', 'Groom'];

  static DefenderType defenderTypeForChart(EventChart? chart) {
    switch (chart) {
      case EventChart.warMarch:
        return DefenderType.knight;
      case EventChart.arcane:
      case EventChart.wilds:
        return DefenderType.beast;
      case EventChart.deeps:
        return DefenderType.bastionDefender;
      case EventChart.tradeRoad:
      case EventChart.hearth:
      case null:
        return DefenderType.knight;
    }
  }

  String storyFor({required ChartEvent event, required String bastionName}) {
    return 'Came to $bastionName in the wake of ${event.name}.';
  }

  GeneratedRecruit generateDefender({
    required ChartEvent event,
    required String bastionName,
  }) {
    final type = defenderTypeForChart(event.chart);
    return GeneratedRecruit(
      name: _names.generate(1).first,
      defenderType: type,
      description: _defenderDescription(type, bastionName),
      acquisitionStory: storyFor(event: event, bastionName: bastionName),
    );
  }

  GeneratedRecruit generateHireling({
    required ChartEvent event,
    required String bastionName,
  }) {
    final pool = _rolesByChart[event.chart] ?? _fallbackRoles;
    return GeneratedRecruit(
      name: _names.generate(1).first,
      role: pool[_random.nextInt(pool.length)],
      description: 'Taken into service at $bastionName.',
      acquisitionStory: storyFor(event: event, bastionName: bastionName),
    );
  }

  String _defenderDescription(DefenderType type, String bastionName) {
    switch (type) {
      case DefenderType.knight:
        return 'A seasoned warrior sworn to $bastionName.';
      case DefenderType.beast:
        return 'A wild creature that has taken to $bastionName.';
      case DefenderType.bastionDefender:
        return 'A steady guard now stationed at $bastionName.';
    }
  }
}
