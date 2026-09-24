import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/animated_die.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';

/// Spatial replay of a [BastionCombatResult]: defenders left, dice centre,
/// enemies right. [revealedRound] is the highest round index revealed so far
/// (-1 before the first round).
class CombatArena extends StatelessWidget {
  final BastionCombatResult result;
  final int revealedRound;
  final bool rolling;

  const CombatArena({
    super.key,
    required this.result,
    required this.revealedRound,
    required this.rolling,
  });

  int get _upto {
    final max = result.rounds.length - 1;
    if (revealedRound < -1) return -1;
    return revealedRound > max ? max : revealedRound;
  }

  int get _settledUpto => rolling ? _upto - 1 : _upto;

  int get _enemiesRemaining {
    var remaining = result.startingEnemies;
    for (var i = 0; i <= _settledUpto; i++) {
      remaining -= result.rounds[i].enemiesKilled;
    }
    return remaining < 0 ? 0 : remaining;
  }

  Set<String> get _deadIds {
    final dead = <String>{};
    for (var i = 0; i <= _settledUpto; i++) {
      for (final roll in result.rounds[i].rolls) {
        if (roll.died) dead.add(roll.defenderId);
      }
    }
    return dead;
  }

  CombatRound? get _currentRound =>
      revealedRound >= 0 && revealedRound < result.rounds.length
          ? result.rounds[revealedRound]
          : null;

  int _facesFor(String id) {
    for (final loadout in result.roster) {
      if (loadout.id == id) return loadout.dice.faces;
    }
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final round = _currentRound;
    final dead = _deadIds;
    final fighting = round == null
        ? const <String>{}
        : round.rolls.map((r) => r.defenderId).toSet();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _column(
            label: 'Defenders',
            children: [
              for (final loadout in result.roster)
                _DefenderCard(
                  loadout: loadout,
                  dead: dead.contains(loadout.id),
                  fighting: fighting.contains(loadout.id),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 96, child: _diceStage(round)),
        const SizedBox(width: 8),
        Expanded(
          child: _column(
            label: 'Enemies',
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < result.startingEnemies; i++)
                    _EnemyToken(alive: i < _enemiesRemaining),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _column({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _diceStage(CombatRound? round) {
    if (round == null || round.rolls.isEmpty) {
      return const SizedBox.shrink();
    }
    final dice = <Widget>[];
    for (final roll in round.rolls) {
      final faces = _facesFor(roll.defenderId);
      for (final value in roll.rolls) {
        dice.add(
          AnimatedDie(
            value: value,
            faces: faces,
            rolling: rolling,
            lethal: !rolling && value < result.deathThreshold,
          ),
        );
      }
    }
    return Column(
      children: [
        Text(
          'Rolls',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: dice,
        ),
      ],
    );
  }
}

class _DefenderCard extends StatelessWidget {
  final DefenderLoadout loadout;
  final bool dead;
  final bool fighting;

  const _DefenderCard({
    required this.loadout,
    required this.dead,
    required this.fighting,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dead ? 0.4 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: fighting ? MedievalColors.parchmentDark : null,
          border: Border.all(color: MedievalColors.goldPale),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            DefenderTypeIcon(type: loadout.type),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loadout.name,
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 13,
                      color: MedievalColors.sepiaInk,
                    ),
                  ),
                  Text(
                    dead ? 'slain' : 'd${loadout.dice.faces}',
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 11,
                      color: dead
                          ? MedievalColors.vermillionDark
                          : MedievalColors.sepiaSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnemyToken extends StatelessWidget {
  final bool alive;

  const _EnemyToken({required this.alive});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: alive
          ? const SizedBox(
              width: 16,
              height: 16,
              child: Icon(
                Icons.dangerous,
                size: 16,
                color: MedievalColors.vermillionDark,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
