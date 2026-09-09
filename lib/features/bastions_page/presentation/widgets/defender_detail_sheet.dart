import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_type_icon.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class DefenderDetailSheet extends StatelessWidget {
  final Defender defender;

  const DefenderDetailSheet({super.key, required this.defender});

  Future<void> _confirmRemove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<DefendersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MedievalColors.parchmentLight,
        title: Text(
          'Remove ${defender.name ?? 'Unnamed Defender'}?',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MedievalColors.vermillion,
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.imFellEnglish(color: MedievalColors.sepiaInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cubit.removeDefender(defender.id);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Defender removed')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to remove defender')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: [0.6, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DefenderTypeIcon(type: defender.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      defender.name ?? 'Unnamed Defender',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MedievalColors.vermillion,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                defender.type.title,
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  color: MedievalColors.sepiaMuted,
                ),
              ),
              if (defender.description != null &&
                  defender.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  defender.description!,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 15,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ],
              if (defender.acquisitionStory != null &&
                  defender.acquisitionStory!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'How they came to serve',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  defender.acquisitionStory!,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: MedievalColors.sepiaInk,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedievalColors.vermillion,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _confirmRemove(context),
                  child: const Text('Remove from Bastion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
