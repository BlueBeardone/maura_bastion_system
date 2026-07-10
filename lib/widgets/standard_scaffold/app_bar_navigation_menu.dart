import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';
import 'package:maura_bastion_system/features/about_page/about_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_main_screen.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';

class AppBarNavigationMenu extends StatelessWidget {
  final List<MainNavigation> navigationItems;

  const AppBarNavigationMenu({super.key, required this.navigationItems});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (!isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: navigationItems.map((buttonItem) {
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
        return navigationItems.map((buttonItem) {
          return PopupMenuItem<MainNavigation>(
            value: buttonItem,
            child: Text(
              buttonItem.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }).toList();
      },
      onSelected: (buttonItem) => _handleNavigation(context, buttonItem),
    );
  }

  void _handleNavigation(BuildContext context, MainNavigation buttonItem) {
    switch (buttonItem) {
      case MainNavigation.about:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutPage()),
        );
        break;
      case MainNavigation.myBastion:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BastionMainScreen()),
        );
        break;
      case MainNavigation.facility:
        final bastions = getFakeBastions();
        final userBastion = bastions.firstWhere(
          (b) => b.id == userBastionId,
          orElse: () => bastions.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BastionPage(bastion: userBastion),
          ),
        );
        break;
      case MainNavigation.hirelings:
        break;
    }
  }
}
