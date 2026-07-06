import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionMainScreen extends StatelessWidget {
  static const Map<String, String> _owners = {
    'bastion_2': 'Lord Gareth Thorne',
    'bastion_3': 'Captain Mira Voss',
    'bastion_4': 'Sage Elowen',
    'bastion_5': 'Merchant Prince Aldrin',
  };

  const BastionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return BlocBuilder<BastionCubit, BastionState>(
      bloc: BastionCubit()..loadBastions(),
      builder: (context, state) {
        if (state is BastionErrorState) {
          return MyErrorWidget(
            message: state.message,
            icon: Icons.error_outline,
            onRetry: () => BastionCubit().loadBastions(),
          );
        }

        if (state is BastionLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BastionLoadedState) {
          return _buildBastionsView(context, state.bastions);
        }

        return const Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildBastionsView(BuildContext context, List<Bastion> bastions) {
    Bastion? userBastion;
    for (final bastion in bastions) {
      if (bastion.id == userBastionId) {
        userBastion = bastion;
        break;
      }
    }
    final otherBastions = bastions.where((bastion) => bastion.id != userBastionId).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your Bastion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            userBastion == null
                ? _buildAddBastionCard(context)
                : _buildBastionCard(context, userBastion, isUserBastion: true),
            const SizedBox(height: 24),
            Text(
              'Other Bastions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.92,
              ),
              itemCount: otherBastions.length,
              itemBuilder: (context, index) {
                return _buildBastionCard(context, otherBastions[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddBastionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add,
          color: theme.colorScheme.primary,
          size: 34,
        ),
      ),
    );
  }

  Widget _buildBastionCard(BuildContext context, Bastion bastion, {bool isUserBastion = false}) {
    final theme = Theme.of(context);
    final themeColors = theme.extension<MainThemeColors>();
    final facilitiesCount = bastion.facilities.length;
    final totalHirelings = (bastion.facilities).fold<int>(0, (sum, f) => sum + (f.hirelingAmount));
    final ownerName = !isUserBastion ? _owners[bastion.id] : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: isUserBastion ? 400 : null,
          decoration: BoxDecoration(
            color: isUserBastion
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.88)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUserBastion ? theme.colorScheme.primary : Colors.transparent,
              width: isUserBastion ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bastion.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              if (ownerName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.85) : theme.colorScheme.onSurface.withValues(alpha: 0.64),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.85) : theme.colorScheme.onSurface.withValues(alpha: 0.64),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: isUserBastion ? 220 : 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: bastion.imgUrl != null
                      ? Image.network(
                          bastion.imgUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _bastionFallbackImage(themeColors, theme);
                          },
                        )
                      : _bastionFallbackImage(themeColors, theme),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                bastion.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Semantics(
                    label: 'Facilities: $facilitiesCount',
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 16,
                          color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$facilitiesCount Facilities',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    label: 'Hirelings: $totalHirelings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalHirelings Hirelings',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUserBastion ? theme.colorScheme.onPrimary.withValues(alpha: 0.92) : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bastionFallbackImage(MainThemeColors? themeColors, ThemeData theme) {
    return Container(
      color: themeColors?.noImageBastion ?? theme.disabledColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.castle,
        color: theme.colorScheme.onPrimary,
        size: 36,
      ),
    );
  }
}
