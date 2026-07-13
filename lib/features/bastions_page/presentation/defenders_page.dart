import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class DefendersPage extends StatelessWidget {
  final List<Defender> defenders;
  final String bastionName;

  const DefendersPage({
    super.key,
    required this.defenders,
    required this.bastionName,
  });

  @override
  Widget build(BuildContext context) {
    final knights = defenders.where((d) => d.type == DefenderType.knight).toList();
    final bastionDefenders = defenders.where((d) => d.type == DefenderType.bastionDefender).toList();
    final beasts = defenders.where((d) => d.type == DefenderType.beast).toList();

    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Defenders of $bastionName',
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 16),
              if (defenders.isEmpty)
                _buildEmptyState()
              else ...[
                if (knights.isNotEmpty) ...[
                  Text(
                    'Knights',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MedievalColors.vermillion,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: knights.map((d) => _buildCompactDefenderCard(d)).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (bastionDefenders.isNotEmpty) ...[
                  Text(
                    'Bastion Defenders',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MedievalColors.vermillion,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: bastionDefenders.map((d) => _buildCompactDefenderCard(d)).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (beasts.isNotEmpty) ...[
                  Text(
                    'Beasts',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MedievalColors.vermillion,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: beasts.map((d) => _buildCompactDefenderCard(d)).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
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
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.shield_outlined, size: 48, color: MedievalColors.sepiaMuted),
              const SizedBox(height: 12),
              Text(
                'No defenders stationed at this bastion',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDefenderCard(Defender defender) {
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypeIcon(defender.type),
              const SizedBox(width: 10),
              Text(
                defender.name ?? 'Unnamed Defender',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: defender.name != null
                      ? MedievalColors.vermillion
                      : MedievalColors.sepiaMuted,
                  fontStyle: defender.name == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(DefenderType type) {
    IconData iconData;
    switch (type) {
      case DefenderType.knight:
        iconData = Icons.shield;
      case DefenderType.bastionDefender:
        iconData = Icons.castle;
      case DefenderType.beast:
        iconData = Icons.pets;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchmentDark,
      ),
      child: Icon(iconData, size: 20, color: MedievalColors.sepiaMuted),
    );
  }
}
