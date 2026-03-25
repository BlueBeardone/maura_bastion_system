import 'package:flutter/material.dart';
import 'package:maura_bastion_system/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/widgets/about_page/about_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.antiAlias,
        title: Text("Bastions", style: Theme.of(context).textTheme.titleLarge,),
        centerTitle: false,
        actions: _appBarActions(context),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}

List<Widget> _appBarActions(BuildContext context) {
  return MainNavigation.values.map((buttonItem) => FittedBox(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: switch (buttonItem) {
        MainNavigation.about => () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => AboutPage()),
          );
        },
        MainNavigation.basic => () {},
        MainNavigation.special => () {},
        MainNavigation.myBastion => () {},
        MainNavigation.hirelings => () {},
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(buttonItem.title, style: Theme.of(context).textTheme.titleMedium,),
      ),
    ),
  )).toList();
}

