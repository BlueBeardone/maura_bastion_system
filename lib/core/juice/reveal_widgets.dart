import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';

bool _reducedMotion(BuildContext context) =>
    context.getInheritedWidgetOfExactType<MediaQuery>()?.data.disableAnimations ??
    false;

class _JuicePainterColors {
  static const golds = [
    MedievalColors.goldBright,
    MedievalColors.goldLeaf,
    MedievalColors.goldPale,
  ];
}

class _SparklePainter extends CustomPainter {
  final double t;

  _SparklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final dist = 8 + 34 * t + (i % 3) * 6 * t;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      paint.color =
          _JuicePainterColors.golds[i % 3].withValues(alpha: 1 - t);
      canvas.drawCircle(pos, 2.5 * (1 - t) + 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.t != t;
}

class StampIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final SfxClip? sfx;
  final bool haptic;

  const StampIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.sfx,
    this.haptic = false,
  });

  @override
  State<StampIn> createState() => _StampInState();
}

class _StampInState extends State<StampIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    final sfx = widget.sfx;
    if (sfx != null) Juice.sfx(sfx);
    if (widget.haptic) Juice.heavy();
    if (_reducedMotion(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reducedMotion(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final scale = reduced ? 1.0 : 1.0 + 0.35 * (1 - t);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class Shake extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const Shake({super.key, required this.child, this.trigger = false});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _lastTrigger = false;

  @override
  void initState() {
    super.initState();
    _maybeShake();
  }

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeShake();
  }

  void _maybeShake() {
    if (widget.trigger == _lastTrigger) return;
    _lastTrigger = widget.trigger;
    if (!widget.trigger) return;
    Juice.sfx(SfxClip.dice);
    Juice.tap();
    if (_reducedMotion(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = _controller.isAnimating
            ? math.sin(t * math.pi * 4) * 6 * (1 - t)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slide;

  const FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slide = 0.2,
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (_reducedMotion(context)) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reducedMotion(context);
    final slide = reduced ? 0.0 : widget.slide;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(0, slide * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class SparkleOverlay extends StatefulWidget {
  final Widget child;
  final bool auto;
  final bool trigger;
  final SfxClip? sfx;

  const SparkleOverlay({
    super.key,
    required this.child,
    this.auto = false,
    this.trigger = false,
    this.sfx,
  });

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _lastTrigger = false;

  @override
  void initState() {
    super.initState();
    if (widget.auto) _start();
  }

  @override
  void didUpdateWidget(covariant SparkleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && widget.trigger != _lastTrigger) _start();
    _lastTrigger = widget.trigger;
  }

  void _start() {
    if (_controller.isAnimating) return;
    final sfx = widget.sfx;
    if (sfx != null) Juice.sfx(sfx);
    if (_reducedMotion(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _SparklePainter(_controller.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One-shot gold burst at screen center, inserted into the root overlay.
class SparkleBurst {
  SparkleBurst._();

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: SparkleBurstView(
              onComplete: () {
                if (entry.mounted) entry.remove();
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class SparkleBurstView extends StatefulWidget {
  final VoidCallback? onComplete;

  const SparkleBurstView({super.key, this.onComplete});

  @override
  State<SparkleBurstView> createState() => _SparkleBurstViewState();
}

class _SparkleBurstViewState extends State<SparkleBurstView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (_reducedMotion(context)) {
      _controller.value = 1;
      scheduleMicrotask(() => widget.onComplete?.call());
      return;
    }
    _controller.forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          CustomPaint(painter: _SparklePainter(_controller.value)),
    );
  }
}
