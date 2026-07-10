import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';

class OrnamentalDivider extends StatelessWidget {
  final double thickness;
  final Color color;

  const OrnamentalDivider({
    super.key,
    this.thickness = 2.0,
    this.color = MedievalColors.goldPale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: thickness,
            color: color,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.diamond,
            size: thickness * 4,
            color: color,
          ),
        ),
        Expanded(
          child: Container(
            height: thickness,
            color: color,
          ),
        ),
      ],
    );
  }
}
