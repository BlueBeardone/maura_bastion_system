import 'package:flutter/material.dart';

class BusyButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const BusyButton({
    super.key,
    required this.busy,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: style,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}
