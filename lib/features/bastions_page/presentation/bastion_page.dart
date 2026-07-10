import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionPage extends StatelessWidget {
  final Bastion bastion;

  const BastionPage({super.key, required this.bastion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = theme.extension<MainThemeColors>();

    return StandardScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bastion.name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: bastion.facilities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final facility = bastion.facilities[index];
                  return _buildFacilityCard(context, facility, theme, themeColors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard(BuildContext context, Facility facility, ThemeData theme, MainThemeColors? themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            facility.name,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 160,
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
          const SizedBox(height: 10),
          Text(
            facility.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text('Rank: ${facility.rank.title}'),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text('Hirelings: ${facility.hirelingAmount}'),
              ),
            ],
          ),
        ],
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
