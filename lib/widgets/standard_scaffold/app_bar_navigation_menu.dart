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

  Bastion? _findUserBastion(List<Bastion> bastions) {
    final authState = GetIt.I<AuthCubit>().state;
    if (authState is! AuthAuthenticatedState) return null;
    final currentUserId = authState.user.id;
    for (final bastion in bastions) {
      if (bastion.belongsTo(currentUserId)) return bastion;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BlocProvider(
      create: (_) => BastionCubit(
        bastionApi: GetIt.I<BastionApi>(),
        facilityApi: GetIt.I<FacilityApi>(),
        discordAnnouncer: GetIt.I<DiscordAnnouncer>(),
      )..loadBastions(),
      child: BlocBuilder<BastionCubit, BastionState>(
        builder: (context, state) {
          final bastions =
              state is BastionLoadedState ? state.bastions : const <Bastion>[];
          final userBastion = _findUserBastion(bastions);
          final hasUserBastion = userBastion != null;
          final items = widget.navigationItems
              .where((item) => item != MainNavigation.facility || hasUserBastion)
              .toList();

          if (!isMobile) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: items.map((buttonItem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    hoverColor: Theme.of(context).hoverColor,
                    onTap: () => _handleNavigation(context, buttonItem, userBastion),
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
              return items.map((buttonItem) {
                return PopupMenuItem<MainNavigation>(
                  value: buttonItem,
                  child: Text(
                    buttonItem.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).appBarTheme.foregroundColor),
                  ),
                );
              }).toList();
            },
            onSelected: (buttonItem) => _handleNavigation(context, buttonItem, userBastion),
          );
        },
      ),
    );
  }

  Future<void> _handleNavigation(
    BuildContext context,
    MainNavigation buttonItem,
    Bastion? userBastion,
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
          if (userBastion == null) break;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BastionPage(bastionId: userBastion.id, isUserBastion: true),
            ),
          );
          break;
        case MainNavigation.hirelings:
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HirelingsPage(bastion: userBastion),
            ),
          );
          break;
      }
      if (context.mounted) {
        context.read<BastionCubit>().loadBastions();
      }
    } finally {
      _navigationInProgress = false;
    }
  }
}
