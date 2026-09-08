import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BastionTurnDialog extends StatelessWidget {
  final Facility? advancedFacility;
  final Bastion bastion;

  const BastionTurnDialog({
    super.key,
    required this.advancedFacility,
    required this.bastion,
  });

  static Future<void> show(
    BuildContext context, {
    required Facility? advancedFacility,
    required Bastion bastion,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BastionTurnDialog(
        advancedFacility: advancedFacility,
        bastion: bastion,
      ),
    );
  }

  List<Facility> _eligibleFacilities() {
    return bastion.facilities
        .where((f) =>
            f.constructedTurns >= f.constructionTurns &&
            bastion.facilityHirelingCount(f.id) >= f.minimumRequiredHirelings)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleFacilities();
    final String header = advancedFacility != null
        ? 'Construction advanced: ${advancedFacility!.name} '
            '(${advancedFacility!.constructedTurns}/${advancedFacility!.constructionTurns} turns)'
        : 'No facilities under construction.';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bastion Turn',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  header,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    height: 1.4,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: eligible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No facilities ready to grant buffs this turn.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.imFellEnglish(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: MedievalColors.sepiaMuted,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: eligible
                                .map((f) => _buildFacilityTile(context, f))
                                .toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityTile(BuildContext context, Facility facility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        borderRadius: BorderRadius.circular(12),
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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            iconColor: MedievalColors.sepiaSecondary,
            collapsedIconColor: MedievalColors.sepiaSecondary,
            title: Text(
              facility.name,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MedievalColors.vermillion,
              ),
            ),
            subtitle: Text(
              'Rank ${facility.rank.title}',
              style: GoogleFonts.imFellEnglish(
                fontSize: 12,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  facility.description,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 13,
                    height: 1.4,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ),
              if (facility.table != null) ...[
                const SizedBox(height: 8),
                FacilityTableView(table: facility.table!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
