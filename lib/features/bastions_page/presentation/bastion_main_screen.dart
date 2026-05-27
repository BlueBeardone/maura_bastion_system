import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
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
          return Center(child: CircularProgressIndicator());
        }

        if (state is BastionLoadedState) {
          return _buildBastionsView(context, state.bastions);
        } 

        return Center(child: Text('Unknown state'));
      },
    );
  }

  Widget _buildBastionsView(BuildContext context, List<Bastion> bastions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final bastion = bastions[index];
            final themeColors = Theme.of(context).extension<MainThemeColors>();
            return GridTile(
              header: Text(bastion.name, style: Theme.of(context).textTheme.titleMedium),
              footer: Text(bastion.description),
              child: bastion.imgUrl != null
                  ? Image.network(bastion.imgUrl!, fit: BoxFit.cover)
                  : Container(color: themeColors?.noImageBastion ?? Theme.of(context).disabledColor),
            );
          },
          itemCount: bastions.length,
        );
      },
    );
  }
}
