import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/facility_table_view.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class FacilityExpandableCard extends StatefulWidget {
  final Facility facility;
  final int hirelingCount;
  final VoidCallback? onOpen;

  const FacilityExpandableCard({
    super.key,
    required this.facility,
    this.hirelingCount = 0,
    this.onOpen,
  });

  @override
  State<FacilityExpandableCard> createState() => _FacilityExpandableCardState();
}

class _FacilityExpandableCardState extends State<FacilityExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final isConstructing =
        facility.constructedTurns < facility.constructionTurns;
    return Opacity(
      opacity: isConstructing ? 0.5 : 1.0,
      child: Container(
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
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          facility.name,
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MedievalColors.vermillion,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MedievalColors.vermillionDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Rank ${facility.rank.title}',
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MedievalColors.goldPale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group,
                          size: 14, color: MedievalColors.sepiaSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.hirelingCount} Hirelings',
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 13,
                          color: MedievalColors.sepiaSecondary,
                        ),
                      ),
                      if (isConstructing) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.timer_rounded,
                            size: 14, color: MedievalColors.sepiaSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Construction: '
                          '${facility.constructedTurns}/'
                          '${facility.constructionTurns} turns',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 13,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: MedievalColors.sepiaSecondary,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_expanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            facility.description,
                            style: GoogleFonts.imFellEnglish(
                              fontSize: 15,
                              height: 1.4,
                              color: MedievalColors.sepiaInk,
                            ),
                          ),
                          if (facility.table != null) ...[
                            const SizedBox(height: 8),
                            FacilityTableView(table: facility.table!),
                          ],
                          const SizedBox(height: 8),
                          if (widget.onOpen != null) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: widget.onOpen,
                                child: const Text('Open facility'),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
