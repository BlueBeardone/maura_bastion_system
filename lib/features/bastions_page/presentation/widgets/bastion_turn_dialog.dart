import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_facility_buff.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_buff_card.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class BastionTurnDialog extends StatelessWidget {
  final Facility? advancedFacility;
  final ChartEvent? event;
  final BastionTurnResult? result;
  final int? eventRollNumber;
  final List<BastionTurnFacilityBuff> facilityBuffs;

  const BastionTurnDialog({
    super.key,
    required this.advancedFacility,
    this.event,
    this.result,
    this.eventRollNumber,
    this.facilityBuffs = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required Facility? advancedFacility,
    ChartEvent? event,
    BastionTurnResult? result,
    int? eventRollNumber,
    List<BastionTurnFacilityBuff> facilityBuffs = const [],
  }) {
    return showDialog(
      context: context,
      builder: (_) => BastionTurnDialog(
        advancedFacility: advancedFacility,
        event: event,
        result: result,
        eventRollNumber: eventRollNumber,
        facilityBuffs: facilityBuffs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 8),
                _buildConstructionSection(),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(child: _buildEventSection()),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildFacilityBuffsSection(),
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

  Widget _buildConstructionSection() {
    final facility = advancedFacility;
    if (facility == null) {
      return Text(
        'No facilities under construction.',
        textAlign: TextAlign.center,
        style: GoogleFonts.imFellEnglish(
          fontSize: 16,
          height: 1.4,
          color: MedievalColors.sepiaInk,
        ),
      );
    }
    if (facility.constructedTurns >= facility.constructionTurns) {
      return _buildCallout(
        title: 'Completed!',
        body: facility.name,
        titleColor: MedievalColors.goldLeaf,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.timer_rounded,
          size: 16,
          color: MedievalColors.sepiaSecondary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Construction advanced: ${facility.name} '
            '(${facility.constructedTurns}/${facility.constructionTurns} turns)',
            style: GoogleFonts.imFellEnglish(
              fontSize: 16,
              height: 1.4,
              color: MedievalColors.sepiaInk,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventSection() {
    final e = event;
    if (e == null) {
      return Text(
        'No individual event this turn.',
        textAlign: TextAlign.center,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: MedievalColors.sepiaMuted,
        ),
      );
    }
    final rolledRow = result?.event?.rolledRow;
    final rewardSummary = result?.event?.rewardSummary;
    final dispatch = result?.event?.dispatch;
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
        const SizedBox(height: 4),
        Text(
          e.name,
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MedievalColors.vermillion,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          e.description,
          style: GoogleFonts.imFellEnglish(
            fontSize: 15,
            height: 1.4,
            color: MedievalColors.sepiaInk,
          ),
        ),
        if (rolledRow != null) ...[
          const SizedBox(height: 8),
          _buildCallout(
            title: eventRollNumber == null ? 'Rolled' : 'Rolled $eventRollNumber',
            body: rolledRow,
          ),
        ],
        if (e.table != null) ...[
          const SizedBox(height: 8),
          FacilityTableView(table: e.table!),
        ],
        if (rewardSummary != null) ...[
          const SizedBox(height: 8),
          _buildCallout(title: 'Reward', body: rewardSummary),
        ],
        if (dispatch != null) ...[
          const SizedBox(height: 8),
          _buildCallout(title: 'Dispatch', body: _dispatchBody(dispatch)),
        ],
      ],
    );
  }

  String _dispatchBody(BastionTurnDispatchResult dispatch) {
    final lines = <String>[
      for (final unit in dispatch.units)
        '${unit.name}: ${unit.subtotal} (${unit.rolls.join(', ')})',
      'Total ${dispatch.total} vs DC ${dispatch.dc} \u2014 '
          '${dispatch.success ? 'success!' : 'failure.'}',
    ];
    return lines.join('\n');
  }

  Widget _buildFacilityBuffsSection() {
    if (facilityBuffs.isEmpty) {
      return Text(
        'No facilities are granting benefits this turn.',
        textAlign: TextAlign.center,
        style: GoogleFonts.imFellEnglish(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: MedievalColors.sepiaMuted,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Facilities granting benefits',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(height: 4),
        for (final buff in facilityBuffs) ...[
          FacilityBuffCard(buff: buff),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCallout({
    required String title,
    required String body,
    Color titleColor = MedievalColors.vermillion,
  }) {
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
              title,
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            for (final line in body.split('\n'))
              Text(
                line,
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
}
