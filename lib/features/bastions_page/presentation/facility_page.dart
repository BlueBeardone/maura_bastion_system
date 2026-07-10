import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class FacilityPage extends StatelessWidget {
  final Facility facility;

  const FacilityPage({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = theme.extension<MainThemeColors>();

    return StandardScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 16),
            _buildImage(theme, themeColors),
            const SizedBox(height: 20),
            _buildHirelingsRow(theme),
            const SizedBox(height: 16),
            _buildDescription(theme),
            if (facility.table != null) ...[
              const SizedBox(height: 24),
              _buildTableSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            facility.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Chip(
          label: Text(
            'Rank ${facility.rank.title}',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: MedievalColors.vermillionDark,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildImage(ThemeData theme, MainThemeColors? themeColors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: facility.imgUrl != null
            ? Image.network(
                facility.imgUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return _imageFallback(themeColors, theme);
                },
              )
            : _imageFallback(themeColors, theme),
      ),
    );
  }

  Widget _imageFallback(MainThemeColors? themeColors, ThemeData theme) {
    return Container(
      color: themeColors?.noImageBastion ?? theme.disabledColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.home_work,
        size: 48,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildHirelingsRow(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.people, color: MedievalColors.sepiaSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          '${facility.hirelingAmount} Hirelings',
          style: theme.textTheme.titleMedium?.copyWith(
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      facility.description,
      style: theme.textTheme.bodyLarge,
    );
  }

  Widget _buildTableSection(ThemeData theme) {
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
            style: theme.textTheme.titleMedium?.copyWith(
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
                            ? theme.textTheme.labelLarge?.copyWith(
                                color: MedievalColors.goldPale,
                                fontWeight: FontWeight.bold,
                              )
                            : theme.textTheme.bodyMedium,
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
