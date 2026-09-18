import 'package:maura_bastion_system/data/default_data/events/arcane_events.dart';
import 'package:maura_bastion_system/data/default_data/events/archetype_events.dart';
import 'package:maura_bastion_system/data/default_data/events/deeps_events.dart';
import 'package:maura_bastion_system/data/default_data/events/hearth_events.dart';
import 'package:maura_bastion_system/data/default_data/events/trade_road_events.dart';
import 'package:maura_bastion_system/data/default_data/events/war_march_events.dart';
import 'package:maura_bastion_system/data/default_data/events/wilds_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';

List<ChartEvent> getChartEvents() {
  return [
    ...wildsEvents(),
    ...deepsEvents(),
    ...tradeRoadEvents(),
    ...warMarchEvents(),
    ...hearthEvents(),
    ...arcaneEvents(),
    ...archetypeEvents(),
  ];
}
