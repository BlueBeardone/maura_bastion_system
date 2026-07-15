import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/test_data/bastion/facility_catalog.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class FacilitySelectionPage extends StatelessWidget {
  static const double _cardWidth = 200.0;

  final Bastion bastion;

  const FacilitySelectionPage({super.key, required this.bastion});

  @override
  Widget build(BuildContext context) {
    final catalog = getFacilityCatalog();
    final builtIds = bastion.facilities.map((f) => f.id).toSet();
    final available = catalog.where((f) => !builtIds.contains(f.id)).toList();

    if (available.isEmpty) {
      return StandardScaffold(
        body: Center(
          child: Text(
            'All facilities have been constructed',
            style: GoogleFonts.imFellEnglish(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ),
      );
    }

    final ranks = [Rank.D, Rank.C, Rank.B, Rank.A, Rank.S];
    available.sort((a, b) => ranks.indexOf(a.rank) - ranks.indexOf(b.rank));

    final grouped = <Rank, List<Facility>>{};
    for (final facility in available) {
      grouped.putIfAbsent(facility.rank, () => []).add(facility);
    }

    final widgets = <Widget>[];
    for (final rank in ranks) {
      final facilities = grouped[rank];
      if (facilities == null || facilities.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Rank: ${rank.title}',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
      );

      widgets.add(
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: facilities.map((facility) {
            return _buildFacilityCard(context, facility);
          }).toList(),
        ),
      );
    }

    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widgets,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(BuildContext context, Facility facility) {
    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FacilityPage(
                facility: facility,
                bastion: bastion,
                isUserBastion: true,
                onConstruct: () {
                  GetIt.I<BastionCubit>().addFacility(bastion.id, facility);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )),
            );
          },
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      facility.name,
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MedievalColors.vermillion,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildFramedImage(facility),
                    const SizedBox(height: 8),
                    Text(
                      facility.description,
                      style: GoogleFonts.imFellEnglish(
                        fontSize: 13,
                        height: 1.4,
                        color: MedievalColors.sepiaInk,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _buildFacilityInfoRow(facility),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityInfoRow(Facility facility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.meeting_room, size: 12, color: MedievalColors.sepiaSecondary),
            const SizedBox(width: 3),
            Text(
              'Rank ${facility.rank.title}',
              style: GoogleFonts.imFellEnglish(
                fontSize: 11,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.timer_rounded, size: 12, color: MedievalColors.sepiaSecondary),
            const SizedBox(width: 3),
            Text(
              '${facility.constructionTurns} turns',
              style: GoogleFonts.imFellEnglish(
                fontSize: 11,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.group, size: 12, color: MedievalColors.sepiaSecondary),
            const SizedBox(width: 3),
            Text(
              '${facility.minimumRequiredHirelings} req',
              style: GoogleFonts.imFellEnglish(
                fontSize: 11,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.monetization_on, size: 12, color: MedievalColors.goldLeaf),
            const SizedBox(width: 3),
            Text(
              '${facility.cost} GP',
              style: GoogleFonts.imFellEnglish(
                fontSize: 11,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFramedImage(Facility facility) {
    if (facility.imgUrl != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
        ),
        child: Stack(
          children: [
            ClipRRect(
              child: Image.network(
                facility.imgUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder('No Engraving'),
              ),
            ),
            _nailDot(Alignment.topLeft),
            _nailDot(Alignment.topRight),
            _nailDot(Alignment.bottomLeft),
            _nailDot(Alignment.bottomRight),
          ],
        ),
      );
    }
    return _imagePlaceholder('No Engraving');
  }

  Widget _imagePlaceholder(String label) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.castle, size: 28, color: MedievalColors.sepiaMuted),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.imFellEnglish(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nailDot(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: MedievalColors.goldLeaf,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 1,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
