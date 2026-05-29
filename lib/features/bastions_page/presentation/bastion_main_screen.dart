import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionMainScreen extends StatelessWidget {
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
    final userBastion = bastions.firstWhere(
      (bastion) => bastion.id == userBastionId,
    );
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildBastionCard(context, userBastion, isUserBastion: true),
            const SizedBox(height: 24),
            Text(
              'Other Bastions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildBastionCard(BuildContext context, Bastion bastion, {bool isUserBastion = false}) {
    final theme = Theme.of(context);
    final themeColors = theme.extension<MainThemeColors>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: isUserBastion ? 640 : null,
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: isUserBastion ? 0.92 : 0.78),
                ),
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
