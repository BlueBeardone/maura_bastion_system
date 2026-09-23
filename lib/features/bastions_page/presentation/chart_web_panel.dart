import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/events/archetypes.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';

class ChartWebPanel extends StatelessWidget {
  const ChartWebPanel({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChartPointsCubit>(),
          child: const ChartWebPanel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChartPointsCubit>();
    final points = cubit.state.points;
    final slices = computeChartSlices(points.points);
    String hint;
    if (unlocksRivalry(points.points)) {
      hint = 'Convergence and Rivalry events unlocked';
    } else if (unlocksConvergence(points.points)) {
      hint = 'Convergence events unlocked';
    } else {
      hint = 'Spread points to unlock Convergence events';
    }

    return Scaffold(
      backgroundColor: MedievalColors.parchment,
      appBar: AppBar(
        backgroundColor: MedievalColors.parchmentDark,
        title: Text(
          'The Individual Bastion Turns',
          style: GoogleFonts.cinzel(
            color: MedievalColors.vermillion,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: MedievalColors.sepiaInk,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${points.unassigned} of ${points.earnedPoints} points unassigned',
              style: GoogleFonts.imFellEnglish(
                fontSize: 16,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final chart in EventChart.values)
                  _ChartRow(
                    chart: chart,
                    points: points,
                    slice: _sliceFor(slices, chart),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              hint,
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ChartSlice? _sliceFor(List<ChartSlice> slices, EventChart chart) {
  for (final slice in slices) {
    if (slice.chart == chart) return slice;
  }
  return null;
}

class _ChartRow extends StatelessWidget {
  final EventChart chart;
  final ChartPoints points;
  final ChartSlice? slice;

  const _ChartRow({
    required this.chart,
    required this.points,
    required this.slice,
  });

  String get _sliceText {
    final value = points[chart];
    if (value == 0) return 'never fires';
    return 'rolls ${slice!.rollMin}\u2013${slice!.rollMax}';
  }

  String get _categoryText {
    if (chart.rewardCategories.isEmpty) return 'no materials';
    return chart.rewardCategories.map(_categoryLabel).join(', ');
  }

  static String _categoryLabel(RewardCategory category) {
    switch (category) {
      case RewardCategory.creaturePart:
        return 'creature parts';
      case RewardCategory.meat:
        return 'meat';
      case RewardCategory.blood:
        return 'blood';
      case RewardCategory.metal:
        return 'metal';
      case RewardCategory.stone:
        return 'stone';
      case RewardCategory.wood:
        return 'wood';
      case RewardCategory.weave:
        return 'weave';
      case RewardCategory.herb:
        return 'herbs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = points[chart];
    final dimmed = value == 0;
    final color = dimmed ? MedievalColors.sepiaMuted : MedievalColors.sepiaInk;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chart.displayName,
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '$_categoryText \u00b7 $_sliceText',
                  style: GoogleFonts.imFellEnglish(fontSize: 14, color: color),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: points.canAssign(chart, -1)
                ? () => context.read<ChartPointsCubit>().assign(chart, -1)
                : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: points.canAssign(chart, 1)
                ? () => context.read<ChartPointsCubit>().assign(chart, 1)
                : null,
          ),
        ],
      ),
    );
  }
}
