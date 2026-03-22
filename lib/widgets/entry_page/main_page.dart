import 'package:flutter/material.dart';
import 'package:maura_bastion_system/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/widgets/about_page/about_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Bastions"),
        actionsPadding: EdgeInsets.all(16),
        actions: _appBarActions(context),
        backgroundColor: Theme.of(context).primaryColorLight,
      ),

    );
  }
}

List<Widget> _appBarActions(BuildContext context) {
  return MainNavigation.values.map((buttonItem) => Padding(
    padding: const EdgeInsets.only(right: 64.0),
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
      child: Text(buttonItem.title),
    ),
  )).toList();
}

