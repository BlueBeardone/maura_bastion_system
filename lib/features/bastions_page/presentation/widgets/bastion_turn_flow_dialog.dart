import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_web_news.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

enum _Phase { dispatch, reward }

class BastionTurnFlowDialog extends StatefulWidget {
  final Bastion bastion;
  final ChartTurnRoll roll;
  final String? rolledRow;

  const BastionTurnFlowDialog({
    super.key,
    required this.bastion,
    required this.roll,
    this.rolledRow,
  });

  static Future<void> show(
    BuildContext context, {
    required Bastion bastion,
    required ChartTurnRoll roll,
    String? rolledRow,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ChartPointsCubit>()),
        ],
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: BastionTurnFlowDialog(
            bastion: bastion,
            roll: roll,
            rolledRow: rolledRow,
          ),
        ),
      ),
    );
  }

  @override
  State<BastionTurnFlowDialog> createState() => _BastionTurnFlowDialogState();
}

class _BastionTurnFlowDialogState extends State<BastionTurnFlowDialog> {
  late _Phase _phase;
  final Set<String> _selectedIds = {};
  DispatchResult? _dispatchResult;
  TurnReward? _reward;
  ChartEvent? _bonusArchetype;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _phase =
        widget.roll.event.dispatch == null ? _Phase.reward : _Phase.dispatch;
    if (_phase == _Phase.reward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finalize();
      });
    }
  }

  List<DispatchUnit> get _availableUnits =>
      dispatchUnitsFromBastion(widget.bastion);

  String _diceLabel(DispatchUnit unit) {
    final spec = widget.roll.event.dispatch!;
    final dice = spec.diceFor(unit.type);
    return '${dice.count}d${dice.faces}';
  }

  void _resolve() {
    final selected =
        _availableUnits.where((u) => _selectedIds.contains(u.id)).toList();
    setState(() {
      _dispatchResult = resolveEventDispatch(
        event: widget.roll.event,
        selected: selected,
      );
    });
    _finalize();
  }

  void _finalize() {
    if (_granted) return;
    _granted = true;
    _reward = resolveEventRewards(
      event: widget.roll.event,
      dispatch: _dispatchResult,
    );
    final pointsCubit = context.read<ChartPointsCubit>();
    _bonusArchetype = const ChartTurnEngine().maybeRollArchetype(
      points: pointsCubit.state.points.points,
      rng: Random(),
    );
    final article = notableResultArticle(
      bastion: widget.bastion,
      event: widget.roll.event,
      reward: _reward!,
      bonusArchetype: _bonusArchetype,
    );
    if (article != null) {
      try {
        unawaited(
          GetIt.I<NewspaperApi>().create(article).then((_) {}, onError: (_) {}),
        );
      } catch (_) {}
    }
    setState(() => _phase = _Phase.reward);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [MedievalColors.parchmentLight, MedievalColors.parchmentDark],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bastion Turn',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: SingleChildScrollView(child: _buildBody())),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final event = widget.roll.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Individual Event',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        Text(
          event.name,
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          event.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        if (event.table != null) ...[
          const SizedBox(height: 8),
          FacilityTableView(table: event.table!),
        ],
        if (widget.rolledRow != null) ...[
          const SizedBox(height: 8),
          _buildRolledResultCallout(widget.rolledRow!),
        ],
        const SizedBox(height: 12),
        if (_phase == _Phase.dispatch) _buildDispatchSection(),
        if (_phase == _Phase.reward && _reward != null) _buildRewardSection(),
      ],
    );
  }

  Widget _buildDispatchSection() {
    final spec = widget.roll.event.dispatch!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.prompt,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            color: MedievalColors.sepiaInk,
          ),
        ),
        const SizedBox(height: 4),
        ..._availableUnits.map(_buildUnitTile),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _resolve,
          child: const Text('Resolve'),
        ),
      ],
    );
  }

  Widget _buildUnitTile(DispatchUnit unit) {
    final checked = _selectedIds.contains(unit.id);
    final atCap = _selectedIds.length >= widget.roll.event.dispatch!.maxUnits;
    return CheckboxListTile(
      value: checked,
      onChanged: (checked || !atCap)
          ? (_) => setState(() {
                checked
                    ? _selectedIds.remove(unit.id)
                    : _selectedIds.add(unit.id);
              })
          : null,
      title: Text(
        unit.name,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          color: MedievalColors.sepiaInk,
        ),
      ),
      subtitle: Text(
        _diceLabel(unit),
        style: GoogleFonts.imFellEnglish(
          fontSize: 13,
          color: MedievalColors.sepiaSecondary,
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    final reward = _reward!;
    final dispatch = _dispatchResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Turn resolved',
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        if (dispatch != null) ...[
          const SizedBox(height: 4),
          ...dispatch.unitRolls.map(
            (r) => Text(
              '${r.unit.name}: ${r.subtotal} (${r.rolls.join(', ')})',
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dispatch.success
                ? 'Total ${dispatch.total} vs DC ${dispatch.dc} — success!'
                : 'Total ${dispatch.total} vs DC ${dispatch.dc} — failure.',
            style: GoogleFonts.imFellEnglish(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: dispatch.success
                  ? MedievalColors.sepiaInk
                  : MedievalColors.sepiaMuted,
            ),
          ),
        ],
        if (reward.gold > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${reward.gold} GP',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MedievalColors.vermillion,
            ),
          ),
        ],
        if (reward.materials.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final grant in reward.materials)
            Text(
              '${grant.units} \u00d7 ${grant.reward.name} (Rank ${grant.effectiveRank.title})',
              style: GoogleFonts.imFellEnglish(
                fontSize: 15,
                color: MedievalColors.sepiaInk,
              ),
            ),
        ],
        if (reward.recruit == RewardKind.recruitDefender)
          _rewardLine(
              'A defender offers to join — their arrival will be recorded at the next muster.'),
        if (reward.recruit == RewardKind.recruitHireling)
          _rewardLine(
              'A hireling offers to join — their arrival will be recorded at the next muster.'),
        if (reward.note != null) _rewardLine(reward.note!),
        if (_bonusArchetype != null) ...[
          const SizedBox(height: 12),
          Text(
            'Convergence: ${_bonusArchetype!.name}',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MedievalColors.vermillion,
            ),
          ),
          Text(
            _bonusArchetype!.description,
            style: GoogleFonts.imFellEnglish(
              fontSize: 14,
              height: 1.4,
              color: MedievalColors.sepiaInk,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRolledResultCallout(String rolledRow) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MedievalColors.parchment,
        border: Border.all(color: MedievalColors.goldLeaf),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rolled',
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: MedievalColors.vermillion,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rolledRow,
              style: GoogleFonts.imFellEnglish(
                fontSize: 15,
                height: 1.4,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          height: 1.4,
          color: MedievalColors.sepiaInk,
        ),
      ),
    );
  }
}
