import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class FacilityPage extends StatelessWidget {
  final Facility facility;
  final Bastion bastion;
  final bool isUserBastion;
  final VoidCallback? onConstruct;

  const FacilityPage({
    super.key,
    required this.facility,
    required this.bastion,
    required this.isUserBastion,
    this.onConstruct,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = onConstruct != null;

    if (!isUserBastion) {
      return _FacilityView(
        facility: facility,
        bastion: bastion,
        assigned: bastion.getFacilityHirelings(facility.id),
        unassigned: const [],
        isUserBastion: false,
        isSelectionMode: false,
      );
    }

    if (isSelectionMode) {
      return _FacilityView(
        facility: facility,
        bastion: bastion,
        assigned: const [],
        unassigned: const [],
        isUserBastion: true,
        isSelectionMode: true,
        onConstruct: onConstruct,
      );
    }

    return BlocProvider(
      create: (_) => HirelingsCubit(
        bastionId: bastion.id,
        initialHirelings: bastion.hirelings,
      ),
      child: BlocBuilder<HirelingsCubit, HirelingsState>(
        builder: (context, state) {
          final assigned = state.hirelings
              .where((h) => h.facilityId == facility.id)
              .toList();
          final unassigned = state.hirelings
              .where((h) => h.facilityId == null)
              .toList();
          return _FacilityView(
            facility: facility,
            bastion: bastion,
            assigned: assigned,
            unassigned: unassigned,
            isUserBastion: true,
            isSelectionMode: false,
          );
        },
      ),
    );
  }
}

class _FacilityView extends StatelessWidget {
  final Facility facility;
  final Bastion bastion;
  final List<Hireling> assigned;
  final List<Hireling> unassigned;
  final bool isUserBastion;
  final bool isSelectionMode;
  final VoidCallback? onConstruct;

  const _FacilityView({
    required this.facility,
    required this.bastion,
    required this.assigned,
    required this.unassigned,
    required this.isUserBastion,
    this.isSelectionMode = false,
    this.onConstruct,
  });

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildImage(),
                  const SizedBox(height: 20),
                  _buildHirelingsRow(),
                  if (!isSelectionMode && facility.minimumRequiredHirelings > 0) ...[
                    const SizedBox(height: 8),
                    _buildRequiredInfo(),
                  ],
                  if (isSelectionMode) ...[
                    const SizedBox(height: 12),
                    _buildConstructionInfo(),
                  ],
                  const SizedBox(height: 16),
                  _buildDescription(),
                  if (facility.table != null) ...[
                    const SizedBox(height: 24),
                    _buildTableSection(),
                  ],
                  if (!isSelectionMode) ...[
                    const SizedBox(height: 24),
                    _buildHirelingSection(
                      context,
                      header: 'Assigned Hirelings',
                      hirelings: assigned,
                      isAssigned: true,
                    ),
                    if (isUserBastion && unassigned.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildHirelingSection(
                        context,
                        header: 'Available Hirelings',
                        hirelings: unassigned,
                        isAssigned: false,
                      ),
                    ],
                  ],
                  if (isSelectionMode && onConstruct != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onConstruct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedievalColors.vermillion,
                          foregroundColor: MedievalColors.goldPale,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Construct Facility — ${facility.cost} GP',
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            facility.name,
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildImage() {
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
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
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
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.castle, size: 48, color: MedievalColors.sepiaMuted),
          const SizedBox(height: 8),
          Text(
            'No Engraving',
            style: GoogleFonts.imFellEnglish(
              fontSize: 13,
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
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: MedievalColors.goldLeaf,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 1,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHirelingsRow() {
    if (isSelectionMode) {
      return Row(
        children: [
          Icon(Icons.people, color: MedievalColors.sepiaSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            '${facility.minimumRequiredHirelings} Hirelings Required',
            style: GoogleFonts.imFellEnglish(
              fontSize: 16,
              color: MedievalColors.sepiaSecondary,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.people, color: MedievalColors.sepiaSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          '${assigned.length} Hirelings',
          style: GoogleFonts.imFellEnglish(
            fontSize: 16,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredInfo() {
    return Row(
      children: [
        Icon(Icons.info_outline, color: MedievalColors.goldLeaf, size: 16),
        const SizedBox(width: 6),
        Text(
          '${assigned.length} / ${facility.minimumRequiredHirelings} hirelings required',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: assigned.length >= facility.minimumRequiredHirelings
                ? MedievalColors.sepiaSecondary
                : MedievalColors.vermillion,
          ),
        ),
      ],
    );
  }

  Widget _buildConstructionInfo() {
    return Row(
      children: [
        Icon(Icons.timer_rounded, color: MedievalColors.sepiaSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          '${facility.constructionTurns} turns',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.monetization_on, color: MedievalColors.goldLeaf, size: 16),
        const SizedBox(width: 6),
        Text(
          '${facility.cost} GP',
          style: GoogleFonts.imFellEnglish(
            fontSize: 14,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      facility.description,
      style: GoogleFonts.imFellEnglish(
        fontSize: 15,
        height: 1.4,
        color: MedievalColors.sepiaInk,
      ),
    );
  }

  Widget _buildTableSection() {
    final table = facility.table!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: MedievalColors.parchment,
            border: Border.all(color: MedievalColors.goldLeaf),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            'Facility Table',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: MedievalColors.goldLeaf),
              right: BorderSide(color: MedievalColors.goldLeaf),
              bottom: BorderSide(color: MedievalColors.goldLeaf),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: MedievalColors.goldPale),
                verticalInside: BorderSide(color: MedievalColors.goldPale),
              ),
              columnWidths: table.table.isNotEmpty
                  ? Map.fromEntries(
                      List.generate(
                        table.table.first.length,
                        (i) => MapEntry(i, const FlexColumnWidth()),
                      ),
                    )
                  : const {},
              children: table.table.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;

                return TableRow(
                  decoration: rowIndex == 0
                      ? BoxDecoration(color: MedievalColors.vermillionDark)
                      : BoxDecoration(
                          color: rowIndex.isOdd
                              ? MedievalColors.parchment
                              : MedievalColors.parchmentLight,
                        ),
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Text(
                        cell,
                        textAlign: rowIndex == 0 ? TextAlign.center : TextAlign.start,
                        style: rowIndex == 0
                            ? GoogleFonts.cinzel(
                                fontSize: 13,
                                color: MedievalColors.goldPale,
                                fontWeight: FontWeight.bold,
                              )
                            : GoogleFonts.imFellEnglish(
                                fontSize: 14,
                                color: MedievalColors.sepiaInk,
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHirelingSection(
    BuildContext context, {
    required String header,
    required List<Hireling> hirelings,
    required bool isAssigned,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: MedievalColors.parchment,
            border: Border.all(color: MedievalColors.goldLeaf),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            header,
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MedievalColors.vermillion,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: MedievalColors.goldLeaf),
              right: BorderSide(color: MedievalColors.goldLeaf),
              bottom: BorderSide(color: MedievalColors.goldLeaf),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: hirelings.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.person_off, size: 32, color: MedievalColors.sepiaMuted),
                      const SizedBox(height: 8),
                      Text(
                        'No hirelings assigned to this facility',
                        style: GoogleFonts.imFellEnglish(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: MedievalColors.sepiaMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: hirelings.map((h) {
                      return _buildHirelingCard(context, h, isAssigned);
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHirelingCard(BuildContext context, Hireling hireling, bool isAssigned) {
    return SizedBox(
      width: 170,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isUserBastion
              ? () {
                  final cubit = context.read<HirelingsCubit>();
                  if (isAssigned) {
                    cubit.dismissHireling(hireling.id);
                  } else {
                    cubit.assignHireling(hireling.id, facility.id);
                  }
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: MedievalColors.parchment.withAlpha(180),
              border: Border.all(color: MedievalColors.goldPale.withAlpha(120)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHirelingPortrait(hireling),
                const SizedBox(height: 6),
                Text(
                  hireling.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hireling.role != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hireling.role!,
                    style: GoogleFonts.imFellEnglish(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: MedievalColors.sepiaSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHirelingPortrait(Hireling hireling) {
    const double portraitSize = 80;

    if (hireling.imgUrl != null) {
      return Container(
        width: portraitSize,
        height: portraitSize,
        decoration: BoxDecoration(
          border: Border.all(color: MedievalColors.goldPale, width: 1.5),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            hireling.imgUrl!,
            width: portraitSize,
            height: portraitSize,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _hirelingPortraitPlaceholder(),
          ),
        ),
      );
    }
    return _hirelingPortraitPlaceholder();
  }

  Widget _hirelingPortraitPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        shape: BoxShape.circle,
        color: MedievalColors.parchment.withAlpha(120),
      ),
      child: Icon(
        Icons.person,
        size: 36,
        color: MedievalColors.sepiaMuted,
      ),
    );
  }
}
