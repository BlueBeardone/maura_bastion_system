import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BastionAttackDialog extends StatelessWidget {
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
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
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
          '$enemyCount \u00d7 ${enemy.name}',
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          enemy.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        const SizedBox(height: 8),
        if (result.roster.isNotEmpty) ...[
          Text(
            'Defenders',
            style: GoogleFonts.imFellEnglish(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MedievalColors.sepiaSecondary,
            ),
          ),
          for (final defender in result.roster)
            _line('${defender.name}: d${defender.dice.faces}'),
          const SizedBox(height: 8),
        ],
        if (result.rounds.isEmpty)
          _line('No defenders stand ready. The gates are thrown open.')
        else
          for (var i = 0; i < result.rounds.length; i++) ...[
            FadeSlide(
              delay: Duration(milliseconds: 200 * i),
              child: Text(
                'Round ${i + 1}',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
            ),
            for (final roll in result.rounds[i].rolls)
              _line(
                '${roll.defenderName}: ${roll.rolls.join(', ')}'
                '${roll.died ? ' \u2014 slain' : ''}',
              ),
            const SizedBox(height: 4),
          ],
        Center(
          child: StampIn(
            sfx: SfxClip.stamp,
            haptic: true,
            child: _AttackVerdict(won: result.won),
          ),
        ),
        if (result.won && loot != null) ...[
          const SizedBox(height: 8),
          for (final grant in loot!.materials)
            _line(
              '${grant.units} \u00d7 ${grant.reward.name} '
              '(Rank ${grant.effectiveRank.title})',
            ),
          if (loot!.note != null) _line(loot!.note!),
        ],
        if (!result.won && destroyedFacilityName != null) ...[
          const SizedBox(height: 8),
          _line(
            'The $destroyedFacilityName is destroyed. '
            'Rebuild it to restore its benefits.',
          ),
        ],
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
