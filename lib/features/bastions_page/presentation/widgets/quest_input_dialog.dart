import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class QuestInputDialog extends StatefulWidget {
  const QuestInputDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const QuestInputDialog(),
    );
  }

  @override
  State<QuestInputDialog> createState() => _QuestInputDialogState();
}

class _QuestInputDialogState extends State<QuestInputDialog> {
  final TextEditingController _controller = TextEditingController();

  bool get _hasQuest => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              MedievalColors.parchmentLight,
              MedievalColors.parchmentDark,
            ],
            stops: [0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: CustomPaint(
          painter: ParchmentBorderPainter(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quest:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MedievalColors.vermillion,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  autofocus: true,
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 14,
                    color: MedievalColors.sepiaInk,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the quest the party undertook…',
                    hintStyle: GoogleFonts.imFellEnglish(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: MedievalColors.sepiaMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_hasQuest) {
                      Navigator.of(context).pop(_controller.text.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _hasQuest
                          ? () => Navigator.of(context).pop(_controller.text.trim())
                          : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
