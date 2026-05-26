import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/features/about_page/about_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_main_screen.dart';

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
        actions: _appBarActions(context),
        actionsPadding: EdgeInsets.only(right: 50),
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: body,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  List<Widget> _appBarActions(BuildContext context) {
    return MainNavigation.values.map((buttonItem) => FittedBox(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        hoverColor: Theme.of(context).hoverColor,
        onTap: switch (buttonItem) {
          MainNavigation.about => () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AboutPage()),
            );
          },
          MainNavigation.myBastion => () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => BastionMainScreen()),
            );
          },
          MainNavigation.facility => () {},
          MainNavigation.hirelings => () {},
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(buttonItem.title, style: Theme.of(context).textTheme.titleMedium,),
        ),
      ),
    )).toList();
  }
}