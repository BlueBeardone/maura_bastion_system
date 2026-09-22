import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/default_data/events/chart_events_catalog.dart';
import 'package:maura_bastion_system/data/models/bastion/individual_bastion_event.dart';
import 'package:maura_bastion_system/data/models/bastion/individual_bastion_events_catalog.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

class EventsBrowserView extends StatelessWidget {
  const EventsBrowserView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Events Reference', style: theme.textTheme.titleLarge),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: const BackButton(),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, 'Individual Bastion Events (d100)'),
          _explainerCard(
            context,
            'Once per Individual Bastion Turn, roll 1d100 on this table and apply the '
            'matching event to your Bastion. Each card shows the range of rolls it covers.',
          ),
          ...getIndividualBastionEventsCatalog().map((e) => _individualEventCard(context, e)),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Chart events'),
          _explainerCard(
            context,
            'Charts (The Wilds, The Deeps, The Trade Road, The War March, The Hearth, '
            'The Arcane) collect points from quests. Each turn, a quiet roll decides '
            'whether anything happens; otherwise the chart with the largest slice is '
            'picked and an event matching your points tier (basic, skilled, master, '
            'legend) is rolled from that chart. Archetype events are convergence and '
            'rivalry events that can trigger when their related charts have enough points.',
          ),
          ..._chartEventGroups(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _chartEventGroups(BuildContext context) {
    final events = getChartEvents();
    final widgets = <Widget>[];
    for (final chart in EventChart.values) {
      final chartEvents =
          events.where((e) => e.chart == chart && !e.isArchetype).toList();
      if (chartEvents.isEmpty) continue;
      widgets.add(_groupHeader(context, chart.displayName));
      for (final event in chartEvents) {
        widgets.add(_chartEventCard(context, event));
      }
    }
    final archetypes = events.where((e) => e.isArchetype).toList();
    if (archetypes.isNotEmpty) {
      widgets.add(_groupHeader(context, 'Archetype events'));
      for (final event in archetypes) {
        widgets.add(_chartEventCard(context, event));
      }
    }
    return widgets;
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _groupHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _explainerCard(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  String? _rewardText(ChartEvent event) {
    final reward = event.reward;
    if (reward.kind == RewardKind.none) return reward.note;
    final buffer = StringBuffer('Reward: ${_capitalize(reward.kind.name)}');
    if (reward.kind == RewardKind.material) {
      final dice = reward.unitDice;
      buffer.write(
        ' (${dice.count}d${dice.faces} units per category pick, '
        '${reward.picks} ${reward.picks == 1 ? 'pick' : 'picks'})',
      );
    }
    final note = reward.note;
    if (note != null) {
      buffer.write(' — $note');
    }
    return buffer.toString();
  }

  Widget _individualEventCard(BuildContext context, IndividualBastionEvent event) {
    final table = event.table;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(event.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                _chip(context, '${event.rollMin}–${event.rollMax}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
            if (table != null && table.table.isNotEmpty) ...[
              const SizedBox(height: 12),
              _eventTable(context, table),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartEventCard(BuildContext context, ChartEvent event) {
    final dispatch = event.dispatch;
    final rewardText = _rewardText(event);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(event.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                _chip(context, _capitalize(event.tier.name)),
                if (event.isArchetype) ...[
                  const SizedBox(width: 4),
                  _chip(context, 'Archetype'),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
            if (dispatch != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dispatch: ${dispatch.prompt} '
                '(max ${dispatch.maxUnits} units, DC ${dispatch.dc})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (event.isArchetype && event.minPointsPerChart > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Gating: ${event.minPointsPerChart}+ points on each of: '
                '${event.relatedCharts.map((c) => c.displayName).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (rewardText != null) ...[
              const SizedBox(height: 4),
              Text(rewardText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventTable(BuildContext context, FacilityTable table) {
    final rows = table.table;
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.dividerColor),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == 0 ? theme.colorScheme.surfaceContainerHighest : null,
            ),
            children: [
              for (final cell in rows[i])
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    cell,
                    style: i == 0
                        ? theme.textTheme.labelLarge
                        : theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
