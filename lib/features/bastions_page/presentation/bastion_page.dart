import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/defenders_page.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionPage extends StatelessWidget {
  static const double _cardWidth = 200.0;

  final Bastion bastion;
  final bool isUserBastion;

  const BastionPage({
    super.key,
    required this.bastion,
    this.isUserBastion = false,
  });

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bastion.name,
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 8),
              bastion.description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        bastion.description,
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 15,
                          height: 1.4,
                          color: MedievalColors.sepiaInk,
                        ),
                      ),
                    )
                  : const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: bastion.facilities.map((facility) {
                  return _buildFacilityCard(context, facility);
                }).toList(),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildBastionHirelingsSection(context),
                  if (bastion.defenders.isNotEmpty)
                    _buildDefendersSection(context),
                ],
              ),
            ],
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
                isUserBastion: isUserBastion,
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
                    Row(
                      children: [
                        Icon(Icons.meeting_room, size: 14, color: MedievalColors.sepiaSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Rank ${facility.rank.title}',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.group, size: 14, color: MedievalColors.sepiaSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${bastion.facilityHirelingCount(facility.id)}',
                          style: GoogleFonts.imFellEnglish(
                            fontSize: 12,
                            color: MedievalColors.sepiaSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildBastionHirelingsSection(BuildContext context) {
    final allHirelings = <Facility, List<Hireling>>{};
    for (final facility in bastion.facilities) {
      final facilityHirelings = bastion.getFacilityHirelings(facility.id);
      if (facilityHirelings.isNotEmpty) {
        allHirelings[facility] = facilityHirelings;
      }
    }

    if (allHirelings.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hirelings of ${bastion.name}',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MedievalColors.vermillion,
                ),
              ),
              const SizedBox(height: 12),
              ...allHirelings.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        entry.key.name,
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MedievalColors.sepiaSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((h) {
                          return _buildBastionHirelingChip(context, h, entry.key);
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDefendersSection(BuildContext context) {
    final knights = bastion.defenders.where((d) => d.type == DefenderType.knight).length;
    final bastionDefenders = bastion.defenders.where((d) => d.type == DefenderType.bastionDefender).length;
    final beasts = bastion.defenders.where((d) => d.type == DefenderType.beast).length;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DefendersPage(
              bastionId: bastion.id,
              initialDefenders: bastion.defenders,
              bastionName: bastion.name,
            ),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
                          color: MedievalColors.parchmentDark,
                        ),
                        child: Icon(Icons.shield, size: 20, color: MedievalColors.sepiaMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Defenders of ${bastion.name}',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MedievalColors.vermillion,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: MedievalColors.goldPale),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (knights > 0)
                    _buildDefenderTypeRow(Icons.shield, 'Knights', knights),
                  if (bastionDefenders > 0)
                    _buildDefenderTypeRow(Icons.castle, 'Bastion Defenders', bastionDefenders),
                  if (beasts > 0)
                    _buildDefenderTypeRow(Icons.pets, 'Beasts', beasts),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefenderTypeRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
              color: MedievalColors.parchmentDark,
            ),
            child: Icon(icon, size: 16, color: MedievalColors.sepiaMuted),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: GoogleFonts.imFellEnglish(
              fontSize: 13,
              color: MedievalColors.sepiaSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBastionHirelingChip(BuildContext context, Hireling hireling, Facility facility) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FacilityPage(
            facility: facility,
            bastion: bastion,
            isUserBastion: isUserBastion,
          )),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MedievalColors.parchment,
          border: Border.all(color: MedievalColors.goldPale.withAlpha(120)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
                color: MedievalColors.parchmentDark,
              ),
              child: Icon(Icons.person, size: 16, color: MedievalColors.sepiaMuted),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hireling.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MedievalColors.vermillion,
                  ),
                ),
                if (hireling.role != null)
                  Text(
                    hireling.role!,
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: MedievalColors.sepiaSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}