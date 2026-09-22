import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';

class DefendersExplainerView extends StatelessWidget {
  const DefendersExplainerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('How Defenders Work', style: theme.textTheme.titleLarge),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: const BackButton(),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(context, 'What defenders are', [
            'Defenders protect your Bastion when it is attacked or sieged. '
                'They live in your Bastion and take part in events that ask you to '
                'send defenders.',
          ]),
          _sectionCard(context, 'Defender types', [
            'Knight — the strongest defender. Knights roll 1d12 when defending. '
                'They arrive through events such as the Duel and the Ronin.',
            'Bastion Defender — your standard guard. Rolls 1d6 when defending.',
            'Beast — a wild creature. Beasts roll 1d10 when defending.',
          ], types: DefenderType.values),
          _sectionCard(context, 'How to get defenders', [
            'Sellswords: eight defenders arrive at your gates; take as many as you can.',
            'Duel: a wandering knight challenges one of your defenders; '
                'if your defender survives three rolls against him, you win '
                'and he joins as a knight.',
            'Ronin: win his game of chance and the knight joins for free, or hire him for 250 GP.',
            'Quest rewards: some events recruit a defender as their reward.',
            'Animal Rescue: a saved animal can join as an extra beast defender.',
          ]),
          _sectionCard(context, 'Defending your Bastion', [
            'When your Bastion is attacked, your defenders fight off the attackers. '
                'A Surprise Attack lists a maximum number of attackers (6 for D-Rank, '
                '18 for C-Rank) and rolls a d8 per rank above D for the attacker count.',
            'If you successfully defend, roll once on the Reward table. You may use siege weapons.',
            'Repelling the attack by destroying your Battlements or similar defenses '
                'prevents all defenders from being lost, but yields no rewards.',
          ]),
          _sectionCard(context, 'Defenders in events', [
            'Something Found: hunters (defenders) can be sent out for rewards.',
            'Request for Aid: send up to 4 defenders and/or hirelings per rank above D; '
                'roll 1d6 for each. 12 or more total per rank above D solves the problem.',
            'Vermin Infestation: send up to 4 defenders (1d6 each) and beasts (1d10 each); '
                'a combined total of 10 or more succeeds.',
            'Guest: a Mercenary Guest provides one additional Bastion Defender and needs no housing.',
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    String title,
    List<String> paragraphs, {
    List<DefenderType> types = const [],
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (types.isNotEmpty) ...[
              for (final type in types)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefenderTypeIcon(type: type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.title, style: theme.textTheme.titleSmall),
                            Text(
                              paragraphs[types.indexOf(type)],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ] else
              for (final paragraph in paragraphs) ...[
                Text(paragraph, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}