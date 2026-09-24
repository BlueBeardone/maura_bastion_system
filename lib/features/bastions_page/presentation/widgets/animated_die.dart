import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';

/// A square numeral die that tumbles while [rolling] and settles on [value].
/// A settled value strictly below the combat death threshold is marked
/// vermillion via [lethal].
class AnimatedDie extends StatefulWidget {
  final int? value;
  final int faces;
  final bool rolling;
  final bool lethal;

  const AnimatedDie({
    super.key,
    required this.value,
    required this.faces,
    required this.rolling,
    this.lethal = false,
  });

  @override
  State<AnimatedDie> createState() => _AnimatedDieState();
}

class _AnimatedDieState extends State<AnimatedDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.rolling) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.rolling && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settled = !widget.rolling;
    final color = settled && widget.lethal
        ? MedievalColors.vermillionDark
        : MedievalColors.sepiaInk;
    final border = settled && widget.lethal
        ? MedievalColors.vermillionDark
        : MedievalColors.goldLeaf;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final int face;
        if (widget.rolling) {
          final ticks = (_controller.value * 12).floor();
          face = ticks % widget.faces + 1;
        } else {
          face = widget.value ?? 1;
        }
        return Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MedievalColors.parchment,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$face',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
