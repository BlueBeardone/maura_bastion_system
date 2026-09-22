import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';
import 'package:maura_bastion_system/features/about_page/defenders_explainer_view.dart';
import 'package:maura_bastion_system/features/about_page/events_browser_view.dart';
import 'package:maura_bastion_system/features/about_page/theme_reference_view.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static JuiceSettings? _settings() {
    try {
      return GetIt.I<JuiceSettings>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = Scaffold(
      appBar: AppBar(
        title: const Text('About Bastions'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: const BackButton(),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(builder: (context) => _aboutPageContents(context)),
    );
    final settings = _settings();
    if (settings == null) return page;
    return BlocProvider<JuiceSettings>.value(value: settings, child: page);
  }

  Widget _aboutPageContents(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bastions', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'How your stronghold works',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_settings() != null)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              title: const Text('Sound effects'),
              subtitle: const Text('Sound effects and haptics for bastion moments'),
              value: !context.watch<JuiceSettings>().state.muted,
              onChanged: (_) => _settings()?.toggle(),
            ),
          ),
        _card(
          context,
          icon: Icons.castle,
          title: 'Bastions',
          message: 'A Bastion is a player-owned stronghold built over time. The '
              'design, from a wizard\'s tower to a rogue\'s casino, is entirely '
              'up to you. Construction of a Bastion becomes available after you '
              'pass the D-Rank exam.',
        ),
        _card(
          context,
          icon: Icons.foundation,
          title: 'Starting your Bastion',
          message: 'You can start your own Bastion by building a D-Rank '
              'facility, such as the Barracks, a Bedroom, or a Parlor. The first '
              'D-Rank facility you build is free. Upon completion, you have '
              'your Bastion.',
        ),
        _card(
          context,
          icon: Icons.engineering,
          title: 'Construction Turns',
          message: 'Every time you complete a quest (successful or not), you '
              'also get a construction turn. A dungeon counts as two '
              'construction turns. A construction turn does not take any of '
              'your workweek hours.',
        ),
        _card(
          context,
          icon: Icons.groups,
          title: 'Hirelings',
          message: 'Hirelings are maids, butlers, or workers for your Bastion. '
              'They work in certain facilities to keep those facilities '
              'operating.',
        ),
        _card(
          context,
          icon: Icons.person,
          title: 'Individual Bastion Turn',
          message: 'You can issue one Individual Bastion Turn order to each of '
              'your facilities, if applicable. You also roll on the Individual '
              'Bastion Events.',
        ),
        _card(
          context,
          icon: Icons.calendar_month,
          title: 'Monthly Bastion Turn',
          message: 'A Bastion server-wide event that takes one IRL month. You '
              'can find the current Monthly Bastion Turn and its effects in '
              'the Announcements channel.',
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Text('Developer', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          _debugTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Theme reference',
            subtitle:
                'All colors, text sizes, and theme components on a dedicated page.',
            page: const ThemeReferenceView(),
          ),
          _debugTile(
            context,
            icon: Icons.casino_outlined,
            title: 'Events browser',
            subtitle:
                'All Individual Bastion Events and chart events, with how each system works.',
            page: const EventsBrowserView(),
          ),
          _debugTile(
            context,
            icon: Icons.shield_outlined,
            title: 'How defenders work',
            subtitle:
                'Defender types, how to get them, and how they defend your Bastion.',
            page: const DefendersExplainerView(),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon, required String title, required String message}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
