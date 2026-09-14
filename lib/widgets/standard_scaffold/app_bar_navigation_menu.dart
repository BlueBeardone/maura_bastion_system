import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/features/about_page/about_page.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_main_screen.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/hirelings_page.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class AppBarNavigationMenu extends StatefulWidget {
  final List<MainNavigation> navigationItems;

  const AppBarNavigationMenu({super.key, required this.navigationItems});

  @override
  State<AppBarNavigationMenu> createState() => _AppBarNavigationMenuState();
}

class _AppBarNavigationMenuState extends State<AppBarNavigationMenu> {
  bool _navigationInProgress = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (!isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.navigationItems.map((buttonItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              hoverColor: Theme.of(context).hoverColor,
              onTap: () => _handleNavigation(context, buttonItem),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  buttonItem.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return PopupMenuButton<MainNavigation>(
      icon: Icon(
        Icons.menu,
        color: Theme.of(context).appBarTheme.iconTheme?.color,
      ),
      color: Theme.of(context).appBarTheme.backgroundColor,
      itemBuilder: (context) {
        return widget.navigationItems.map((buttonItem) {
          return PopupMenuItem<MainNavigation>(
            value: buttonItem,
            child: Text(
              buttonItem.title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).appBarTheme.foregroundColor),
            ),
          );
        }).toList();
      },
      onSelected: (buttonItem) => _handleNavigation(context, buttonItem),
    );
  }

  Future<void> _handleNavigation(
    BuildContext context,
    MainNavigation buttonItem,
  ) async {
    if (_navigationInProgress) return;
    _navigationInProgress = true;
    try {
      switch (buttonItem) {
        case MainNavigation.about:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AboutPage()),
          );
          break;
        case MainNavigation.myBastion:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BastionMainScreen()),
          );
          break;
        case MainNavigation.facility:
          await _navigateToUserBastion(context);
          break;
        case MainNavigation.hirelings:
          await _navigateToHirelings(context);
          break;
      }
    } finally {
      _navigationInProgress = false;
    }
  }

  Future<Bastion?> _fetchUserBastion() async {
    final cubit = BastionCubit(
      bastionApi: GetIt.I<BastionApi>(),
      facilityApi: GetIt.I<FacilityApi>(),
      discordAnnouncer: GetIt.I<DiscordAnnouncer>(),
    );
    Bastion? result;
    try {
      await cubit.loadBastions();
      final authState = GetIt.I<AuthCubit>().state;
      if (authState is AuthAuthenticatedState) {
        final currentUserId = authState.user.id;
        try {
          result = cubit.state is BastionLoadedState
              ? (cubit.state as BastionLoadedState).bastions
                  .firstWhere((b) => b.belongsTo(currentUserId))
              : null;
        } catch (_) {
          result = null;
        }
      } else {
        result = cubit.state is BastionLoadedState &&
                (cubit.state as BastionLoadedState).bastions.isNotEmpty
            ? (cubit.state as BastionLoadedState).bastions.first
            : null;
      }
    } finally {
      await cubit.close();
    }
    return result;
  }

  Future<void> _navigateToUserBastion(BuildContext context) async {
    final userBastion = await _fetchUserBastion();
    if (userBastion == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BastionPage(bastionId: userBastion.id, isUserBastion: true),
      ),
    );
    if (context.mounted) {
      final underlying = context.read<BastionCubit?>();
      underlying?.loadBastions();
    }
  }

  Future<void> _navigateToHirelings(BuildContext context) async {
    final userBastion = await _fetchUserBastion();
    if (userBastion == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HirelingsPage(bastion: userBastion),
      ),
    );
    if (context.mounted) {
      final underlying = context.read<BastionCubit?>();
      underlying?.loadBastions();
    }
  }
}
