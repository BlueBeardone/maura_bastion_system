import 'package:flutter/material.dart';
import 'package:maura_bastion_system/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/widgets/about_page/about_page.dart';
import 'package:maura_bastion_system/widgets/error/error_widget.dart';
import 'package:maura_bastion_system/widgets/news_paper/news_paper.dart';

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
        actionsPadding: EdgeInsets.only(right: 50),
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: NewspaperLayout(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
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
            MaterialPageRoute(builder: (context) => MyErrorWidget(
              message: """
HELLO 0000000000000000000000000000000000000000000000000000000000000000000000000

""",
            )),
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

