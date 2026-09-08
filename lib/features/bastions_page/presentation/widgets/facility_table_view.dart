import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

class FacilityTableView extends StatelessWidget {
  final FacilityTable table;

  const FacilityTableView({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final rows = table.table;

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
              columnWidths: rows.isNotEmpty
                  ? Map.fromEntries(
                      List.generate(
                        rows.first.length,
                        (i) => MapEntry(i, const FlexColumnWidth()),
                      ),
                    )
                  : const {},
              children: rows.asMap().entries.map((entry) {
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
                        textAlign:
                            rowIndex == 0 ? TextAlign.center : TextAlign.start,
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
}
