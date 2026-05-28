import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/app_bar_navigation_menu.dart';

class StandardScaffold extends StatelessWidget {
  final Widget body;

  const StandardScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.antiAlias,
        title: Text("Bastions", style: Theme.of(context).textTheme.titleLarge,),
        centerTitle: false,
        actions: [
          AppBarNavigationMenu(navigationItems: MainNavigation.values),
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            icon: Icon(Icons.logout, color: Theme.of(context).textTheme.titleMedium?.color,),
            tooltip: 'Logout',
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16),
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SafeArea(child: body),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}