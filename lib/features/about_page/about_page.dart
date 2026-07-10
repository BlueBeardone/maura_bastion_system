import 'package:flutter/material.dart';
import 'package:maura_bastion_system/features/about_page/theme_reference_view.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Bastions"),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: BackButton(),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _aboutPageContents(context),
    );
  }

  Widget _aboutPageContents(BuildContext context) {

    return ListView(
      padding: EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      scrollDirection: Axis.vertical,
      children: [
        _card(
          context: context, 
          title: "Bastions", 
          message: "A Bastions is a player-owned stronghold built over time. The design, from a wizard's tower to a rogue's casino, is entirely up to you. The construction of a Bastion becomes available to you after you've passed the D-Rank exam", 
          color: Colors.amberAccent
        ),
        SizedBox(height: 8,),
        _card(
          context: context, 
          title: "Starting your Bastion", 
          message: "You can start your own Bastion by building a D-Rank Facility, such as the Barracks, a Bedroom or a Parlor. The first D-rank Facility you build is free. Upon completion you have your Bastion.", 
          color: Colors.limeAccent
        ),
        SizedBox(height: 8,),
        _card(
          context: context, 
          title: "Construction Turns", 
          message: "Every time you complete a quest (successful or not), you also get a construction turn. A dungeon counts as two construction turns. A construction turn does not take any of your workweek hours.", 
          color: Colors.greenAccent
        ),
        SizedBox(height: 8,),
        _card(
          context: context, 
          title: "Hirelings", 
          message: "Hirelings are maids, butlers or workers for your Bastion as they work in certain facilities to keep those Facilities operating.", 
          color: Colors.cyanAccent,
        ),
        SizedBox(height: 8,),
        _card(
          context: context, 
          title: "Individual Bastion Turn", 
          message: "You can issue one Individual Bastion Turn order to each one of your facilities if applicable. You also roll on the Individual Bastion Events.", 
          color: Colors.redAccent
        ),
        _card(
          context: context, 
          title: "Monthly Bastion Turn", 
          message: "A Bastions server wide event that takes one irl month. You can Find the current Monthly Bastion Turn and it's effects in the Announcements channel.", 
          color: Colors.redAccent
        ),
        const SizedBox(height: 16,),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.12),
          child: ListTile(
            title: Text('Theme reference', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Open a dedicated page showing all colors, text sizes, and theme components.', style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ThemeReferenceView()),
              );
            },
          ),
        ),
        const SizedBox(height: 8,),
      ],
    );
  }

  Widget _card({required BuildContext context, required String title, required String message, required Color color}) {
    return Card(
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Title(
            color: Colors.black, 
            child: Text(title, style: Theme.of(context).textTheme.titleLarge,)
          ),
          Text(message, style: Theme.of(context).textTheme.bodyLarge,),
        ],
      ),
    );
  }
}