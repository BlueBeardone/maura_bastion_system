import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/turn_engine.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/features/bastions_page/data/filler_store.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_web_news.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/recruit_generator.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_create_form.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/hireling_create_form.dart';
import 'package:maura_bastion_system/features/news_paper/logic/filler_article_generator.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

enum _Phase { dispatch, reward, recruit }

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

  static Future<String?> show(
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
  bool _resolving = false;
  DispatchResult? _dispatchResult;
  TurnReward? _reward;
  String? _rewardSummary;
  ChartEvent? _bonusArchetype;
  bool _granted = false;
  DefendersCubit? _defendersCubit;
  HirelingsCubit? _hirelingsCubit;
  String? _recruitName;
  DefenderType? _recruitType;
  String? _recruitRole;
  bool _recruitDismissed = false;
  bool _creatingRecruit = false;

  DefendersCubit get _cubitForDefenders => _defendersCubit ??= DefendersCubit(
        bastionId: widget.bastion.id,
        defenderApi: GetIt.I<DefenderApi>(),
        discordAnnouncer: GetIt.I.isRegistered<DiscordAnnouncer>()
            ? GetIt.I<DiscordAnnouncer>()
            : null,
        bastionName: widget.bastion.name,
      );

  HirelingsCubit get _cubitForHirelings => _hirelingsCubit ??= HirelingsCubit(
        bastionId: widget.bastion.id,
        hirelingApi: GetIt.I<HirelingApi>(),
        discordAnnouncer: GetIt.I.isRegistered<DiscordAnnouncer>()
            ? GetIt.I<DiscordAnnouncer>()
            : null,
        bastionName: widget.bastion.name,
      );

  @override
  void dispose() {
    _defendersCubit?.close();
    _hirelingsCubit?.close();
    super.dispose();
  }

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

  Future<void> _resolve() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
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
    _rewardSummary = rewardSummaryText(_reward!);
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
    } else {
      _generateFiller();
    }
    setState(() => _phase = _Phase.reward);
  }

  void _generateFiller() {
    try {
      final store = GetIt.I<FillerStore>();
      final points = context.read<ChartPointsCubit>().state.points.points;
      final filler = const FillerArticleGenerator().generate(
        bastion: widget.bastion,
        points: points,
      );
      unawaited(
        store.append(widget.bastion.id, filler).then((_) {}, onError: (_) {}),
      );
    } catch (_) {
      // Filler is cosmetic; never let it break the turn flow.
    }
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
                onPressed: _creatingRecruit
                    ? null
                    : () {
                        final summary = _effectiveRewardSummary;
                        Navigator.of(context)
                            .pop(summary == 'none' ? null : summary);
                      },
                child: const Text('Done'),
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
        StampIn(
          sfx: SfxClip.quill,
          child: Text(
            event.name,
            style: GoogleFonts.cinzel(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: MedievalColors.vermillion,
            ),
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
          FadeSlide(
            delay: const Duration(milliseconds: 350),
            child: _buildRolledResultCallout(widget.rolledRow!),
          ),
        ],
        const SizedBox(height: 12),
        if (_phase == _Phase.dispatch)
          FadeSlide(
            delay: const Duration(milliseconds: 500),
            child: _buildDispatchSection(),
          ),
        if (_phase == _Phase.recruit) _buildRecruitSection(),
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
          onPressed: _resolving ? null : _resolve,
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
      subtitle: Shake(
        trigger: _resolving && _selectedIds.contains(unit.id),
        child: Text(
          _diceLabel(unit),
          style: GoogleFonts.imFellEnglish(
            fontSize: 13,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    final reward = _reward!;
    final dispatch = _dispatchResult;
    int bursts = 5;
    Widget sparkle(Widget child) {
      if (bursts <= 0) return child;
      bursts--;
      return SparkleOverlay(sfx: SfxClip.coin, auto: true, child: child);
    }

    final rollCount = dispatch?.unitRolls.length ?? 0;
    var rewardLineIndex = 0;
    Widget staggered(Widget child) {
      final delay = Duration(
        milliseconds: 250 * rollCount + 250 * rewardLineIndex++,
      );
      return FadeSlide(delay: delay, child: child);
    }

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
          ...dispatch.unitRolls.indexed.map(
            (indexed) {
              final (i, r) = indexed;
              return FadeSlide(
                delay: Duration(milliseconds: 250 * i),
                child: Text(
                  '${r.unit.name}: ${r.subtotal} (${r.rolls.join(', ')})',
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Center(
            child: StampIn(
              sfx: SfxClip.stamp,
              haptic: true,
              child: _MissionStamp(success: dispatch.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dispatch.success
                ? 'Total ${dispatch.total} vs DC ${dispatch.dc} — success!'
                : 'Total ${dispatch.total} vs DC ${dispatch.dc} — failure.',
            style: GoogleFonts.imFellEnglish(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: dispatch.success
                  ? MedievalColors.goldLeaf
                  : MedievalColors.vermillion,
            ),
          ),
        ],
        if (reward.gold > 0) ...[
          const SizedBox(height: 8),
          staggered(
            sparkle(
              Text(
                '${reward.gold} GP',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MedievalColors.vermillion,
                ),
              ),
            ),
          ),
        ],
        if (reward.materials.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final grant in reward.materials)
            staggered(
              sparkle(
                Text(
                  '${grant.units} \u00d7 ${grant.reward.name} (Rank ${grant.effectiveRank.title})',
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 15,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ),
            ),
        ],
        if (reward.recruit == RewardKind.recruitDefender)
          staggered(_buildRecruitOffer(isDefender: true)),
        if (reward.recruit == RewardKind.recruitHireling)
          staggered(_buildRecruitOffer(isDefender: false)),
        if (reward.note != null) staggered(_rewardLine(reward.note!)),
        if (_bonusArchetype != null) ...[
          const SizedBox(height: 12),
          StampIn(
            sfx: SfxClip.fanfare,
            haptic: true,
            child: Text(
              'Convergence: ${_bonusArchetype!.name}',
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MedievalColors.vermillion,
              ),
            ),
          ),
          FadeSlide(
            delay: const Duration(milliseconds: 400),
            child: Text(
              _bonusArchetype!.description,
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                height: 1.4,
                color: MedievalColors.sepiaInk,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecruitOffer({required bool isDefender}) {
    if (_recruitName != null) {
      return SparkleOverlay(
        sfx: SfxClip.coin,
        auto: true,
        child: _rewardLine(
          isDefender
              ? 'A ${_recruitType?.title.toLowerCase() ?? 'defender'}, $_recruitName, joined your bastion.'
              : _hirelingJoinedLine,
        ),
      );
    }
    if (_recruitDismissed) {
      return _rewardLine(
        isDefender
            ? 'A defender offers to join — their arrival will be recorded at the next muster.'
            : 'A hireling offers to join — their arrival will be recorded at the next muster.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rewardLine(
          isDefender
              ? 'A defender offers to join your bastion.'
              : 'A hireling offers to join your bastion.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _creatingRecruit ? null : _automateRecruit,
                child: const Text('Let the bastion handle it'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _creatingRecruit
                    ? null
                    : () => setState(() => _phase = _Phase.recruit),
                child: const Text("I'll make them myself"),
              ),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: _creatingRecruit
                ? null
                : () => setState(() => _recruitDismissed = true),
            child: const Text('Skip for now'),
          ),
        ),
      ],
    );
  }

  String get _hirelingJoinedLine {
    final role = _recruitRole;
    if (role == null || role.isEmpty) {
      return 'A hireling, $_recruitName, joined your bastion.';
    }
    return 'A hireling, $_recruitName ($role), joined your bastion.';
  }

  Future<void> _automateRecruit() async {
    if (_creatingRecruit) return;
    setState(() => _creatingRecruit = true);
    final generator = RecruitGenerator();
    final event = widget.roll.event;
    try {
      if (_reward!.recruit == RewardKind.recruitDefender) {
        final recruit = generator.generateDefender(
          event: event,
          bastionName: widget.bastion.name,
        );
        final ok = await _cubitForDefenders.addDefender(
          name: recruit.name,
          type: recruit.defenderType!,
          description: recruit.description,
          acquisitionStory: recruit.acquisitionStory,
        );
        if (!mounted) return;
        if (!ok) {
          _showRecruitError();
          return;
        }
        setState(() {
          _recruitName = recruit.name;
          _recruitType = recruit.defenderType;
          _recruitRole = null;
        });
      } else if (_reward!.recruit == RewardKind.recruitHireling) {
        final recruit = generator.generateHireling(
          event: event,
          bastionName: widget.bastion.name,
        );
        final ok = await _cubitForHirelings.addHireling(
          name: recruit.name,
          role: recruit.role,
          description: recruit.description,
          acquisitionStory: recruit.acquisitionStory,
        );
        if (!mounted) return;
        if (!ok) {
          _showRecruitError();
          return;
        }
        setState(() {
          _recruitName = recruit.name;
          _recruitType = null;
          _recruitRole = recruit.role;
        });
      }
    } finally {
      if (mounted) setState(() => _creatingRecruit = false);
    }
  }

  void _showRecruitError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong — please try again'),
      ),
    );
  }

  Widget _buildRecruitSection() {
    final event = widget.roll.event;
    final story = RecruitGenerator().storyFor(
      event: event,
      bastionName: widget.bastion.name,
    );
    // Skipping from the recruit phase backs out, leaves the record
    // uncreated, and restores the old flavor-text offer line.
    void skipForNow() => setState(() {
          _recruitDismissed = true;
          _phase = _Phase.reward;
        });
    if (_reward!.recruit == RewardKind.recruitDefender) {
      return Column(
        children: [
          DefenderCreateForm(
            cubit: _cubitForDefenders,
            bastionId: widget.bastion.id,
            bastionName: widget.bastion.name,
            headerText: 'Enlist Your New Defender',
            initialAcquisitionStory: story,
            onCreated: (created) => setState(() {
              _recruitName = created.name;
              _recruitType = created.defenderType;
              _recruitRole = created.role;
              _phase = _Phase.reward;
            }),
          ),
          Center(
            child: TextButton(
              onPressed: _creatingRecruit ? null : skipForNow,
              child: const Text('Skip for now'),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        HirelingCreateForm(
          cubit: _cubitForHirelings,
          bastionId: widget.bastion.id,
          bastionName: widget.bastion.name,
          headerText: 'Recruit Your New Hireling',
          initialAcquisitionStory: story,
          onCreated: (created) => setState(() {
            _recruitName = created.name;
            _recruitType = created.defenderType;
            _recruitRole = created.role;
            _phase = _Phase.reward;
          }),
        ),
        Center(
          child: TextButton(
            onPressed: _creatingRecruit ? null : skipForNow,
            child: const Text('Skip for now'),
          ),
        ),
      ],
    );
  }

  String get _effectiveRewardSummary {
    final base = _rewardSummary ?? 'none';
    final name = _recruitName;
    if (name == null) return base;
    final kind = _reward?.recruit;
    if (kind == RewardKind.recruitDefender) {
      return base.replaceFirst('a new defender',
          'a ${_recruitType?.title.toLowerCase() ?? 'defender'}, $name');
    }
    if (kind == RewardKind.recruitHireling) {
      final role = _recruitRole;
      return base.replaceFirst('a new hireling',
          role == null || role.isEmpty ? 'a hireling, $name' : 'a hireling, $name ($role)');
    }
    return base;
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

class _MissionStamp extends StatelessWidget {
  final bool success;

  const _MissionStamp({required this.success});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: success
              ? MedievalColors.vermillionDark
              : MedievalColors.parchmentMuted,
          border: Border.all(
            color: success ? MedievalColors.goldLeaf : MedievalColors.sepiaMuted,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          success ? 'MISSION HELD' : 'MISSION LOST',
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: success ? MedievalColors.goldPale : MedievalColors.sepiaInk,
          ),
        ),
      ),
    );
  }
}
