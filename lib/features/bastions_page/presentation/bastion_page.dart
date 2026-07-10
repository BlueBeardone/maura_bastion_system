import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionPage extends StatelessWidget {
  static const double _cardWidth = 200.0;

  final Bastion bastion;

  const BastionPage({super.key, required this.bastion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bastion.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              bastion.description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        bastion.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: bastion.facilities.map((facility) {
                  return _buildFacilityCard(context, facility, theme);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(BuildContext context, Facility facility, ThemeData theme) {
    final themeColors = theme.extension<MainThemeColors>();

    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FacilityPage(facility: facility)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  facility.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: facility.imgUrl != null
                        ? Image.network(
                            facility.imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return _facilityFallback(themeColors, theme);
                            },
                          )
                        : _facilityFallback(themeColors, theme),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  facility.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text('Rank: ${facility.rank.title}'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text('Hirelings: ${facility.hirelingAmount}'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _facilityFallback(MainThemeColors? themeColors, ThemeData theme) {
    return Container(
      color: themeColors?.noImageBastion ?? theme.disabledColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.home_work,
        size: 36,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}