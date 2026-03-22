import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Bastions"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColorLight,
        leading: BackButton(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        spacing: 16,
        children: _aboutPageContents(context),
      ),
    );
  }

  List<Widget> _aboutPageContents(BuildContext context) {
    List<Widget> widgets = [];

    widgets.add(SingleChildScrollView(
      clipBehavior: Clip.antiAlias,
      physics: ScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          _card(
            context: context, 
            title: "Bastions", 
            message: "Bastions is a base that you can build that offers temporary buffs and a place for your character to call home.", 
            color: Colors.amberAccent
          ),
          _card(
            context: context, 
            title: "Starting your Bastion", 
            message: "Once you reach level 6 you may bigin to build a Bastion. To start a Bastion you need to buld a Basic Facility.", 
            color: Colors.limeAccent
          ),
        ],
      ),
    ));

    widgets.add(
      SingleChildScrollView(
        controller: ScrollController(),
        physics: ScrollPhysics(),
        clipBehavior: Clip.antiAlias,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            _card(
              context: context, 
              title: "Basic Facilities", 
              message: "Basic Facilities are facilities that allow you to build certain Special facilities and gives a small buff.", 
              color: Colors.greenAccent
            ),
            Flex(direction: Axis.horizontal),
            _card(
              context: context, 
              title: "Special Facilities", 
              message: "Special Facilities are facilities that gives very good buffs that are strong", 
              color: Colors.tealAccent,
            ),
            Flex(direction: Axis.horizontal),
            _card(
              context: context, 
              title: "Hirelings", 
              message: "Hirelings are people that make sure that your Bastion facilities work as certain facilities need hirelings.", 
              color: Colors.purpleAccent,
            ),
            Flex(direction: Axis.horizontal),
            _card(
              context: context, 
              title: "Bastion Turn", 
              message: "A Bastion turn is a turn where specific features from certain facilites activate. Only a dm can allow you to make a Bastion Turn", 
              color: Colors.redAccent
            ),
            Flex(direction: Axis.horizontal),
          ],
        ),
      )
    );

    return widgets;
  }

  Widget _card({required BuildContext context, required String title, required String message, required Color color}) {
    return Container(
      color: color,
      padding: EdgeInsetsGeometry.all(8),
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Title(color: Colors.black, child: Text(title, style: Theme.of(context).textTheme.titleLarge,)),
          Text(message),
        ],
      ),
    );
  }
}