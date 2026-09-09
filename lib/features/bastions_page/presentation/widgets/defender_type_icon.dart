import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';

class DefenderTypeIcon extends StatelessWidget {
  final DefenderType type;

  const DefenderTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (type) {
      case DefenderType.knight:
        iconData = Icons.shield;
      case DefenderType.bastionDefender:
        iconData = Icons.castle;
      case DefenderType.beast:
        iconData = Icons.pets;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchmentDark,
      ),
      child: Icon(iconData, size: 20, color: MedievalColors.sepiaMuted),
    );
  }
}
