import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/combat_arena.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

/// How long the dice tumble before settling.
const Duration kBastionCombatTumble = Duration(milliseconds: 650);

/// How long to pause after a round settles before the next one begins.
const Duration kBastionCombatPause = Duration(milliseconds: 700);

bool _reducedMotion(BuildContext context) =>
    context.getInheritedWidgetOfExactType<MediaQuery>()?.data.disableAnimations ??
    false;

class BastionAttackDialog extends StatefulWidget {
  final BastionEnemy enemy;
  final int enemyCount;
  final BastionCombatResult result;
  final TurnReward? loot;
  final String? destroyedFacilityName;

  const BastionAttackDialog({
    super.key,
    required this.enemy,
    required this.enemyCount,
    required this.result,
    this.loot,
    this.destroyedFacilityName,
  });

  static Future<void> show(
    BuildContext context, {
    required BastionEnemy enemy,
    required int enemyCount,
    required BastionCombatResult result,
    TurnReward? loot,
    String? destroyedFacilityName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: BastionAttackDialog(
          enemy: enemy,
          enemyCount: enemyCount,
          result: result,
          loot: loot,
          destroyedFacilityName: destroyedFacilityName,
        ),
      ),
    );
  }

  @override
  State<BastionAttackDialog> createState() => _BastionAttackDialogState();
}

class _BastionAttackDialogState extends State<BastionAttackDialog> {
  int _revealedRound = -1;
  bool _rolling = false;
  bool _finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_reducedMotion(context) || widget.result.rounds.isEmpty) {
      _finish();
    } else {
      _timer = Timer(kBastionCombatPause, _advance);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (!mounted) return;
    final next = _revealedRound + 1;
    if (next >= widget.result.rounds.length) {
      setState(_finish);
      return;
    }
    setState(() {
      _revealedRound = next;
      _rolling = true;
    });
    Juice.sfx(SfxClip.dice);
    _timer = Timer(kBastionCombatTumble, () {
      if (!mounted) return;
      setState(() => _rolling = false);
      _timer = Timer(kBastionCombatPause, _advance);
    });
  }

  void _finish() {
    _timer?.cancel();
    _revealedRound =
        widget.result.rounds.isEmpty ? -1 : widget.result.rounds.length - 1;
    _rolling = false;
    _finished = true;
  }

  void _skip() => setState(_finish);

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
                'Bastion Attacked',
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
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.enemyCount} \u00d7 ${widget.enemy.name}',
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.enemy.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        const SizedBox(height: 12),
        CombatArena(
          result: widget.result,
          revealedRound: _revealedRound,
          rolling: _rolling,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (!_finished) {
      return Center(
        child: TextButton(
          onPressed: _skip,
          child: const Text('Skip to result'),
        ),
      );
    }
    final result = widget.result;
    final loot = widget.loot;
    final destroyed = widget.destroyedFacilityName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.rounds.isEmpty)
          _line('No defenders stand ready. The gates are thrown open.'),
        Center(
          child: StampIn(
            sfx: SfxClip.stamp,
            haptic: true,
            child: _AttackVerdict(won: result.won),
          ),
        ),
        if (result.won && loot != null) ...[
          const SizedBox(height: 8),
          for (final grant in loot.materials)
            _line(
              '${grant.units} \u00d7 ${grant.reward.name} '
              '(Rank ${grant.effectiveRank.title})',
            ),
          if (loot.note != null) _line(loot.note!),
        ],
        if (!result.won && destroyed != null) ...[
          const SizedBox(height: 8),
          _line(
            'The $destroyed is destroyed. '
            'Rebuild it to restore its benefits.',
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
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

class _AttackVerdict extends StatelessWidget {
  final bool won;

  const _AttackVerdict({required this.won});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: won
              ? MedievalColors.vermillionDark
              : MedievalColors.parchmentMuted,
          border: Border.all(
            color: won ? MedievalColors.goldLeaf : MedievalColors.sepiaMuted,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          won ? 'ATTACK REPELLED' : 'BASTION FALLEN',
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: won ? MedievalColors.goldPale : MedievalColors.sepiaInk,
          ),
        ),
      ),
    );
  }
}
