enum DefenderType {
  knight,
  bastionDefender,
  beast;

  static DefenderType fromString(String type) {
    final normalized = type.toLowerCase().trim().replaceAll(' ', '_');
    switch (normalized) {
      case 'knight':
        return DefenderType.knight;
      case 'bastion_defender':
        return DefenderType.bastionDefender;
      case 'beast':
        return DefenderType.beast;
      default:
        throw ArgumentError('Invalid defender type: $type');
    }
  }
}

extension DefenderTypeExtension on DefenderType {
  String get title {
    switch (this) {
      case DefenderType.knight:
        return 'Knight';
      case DefenderType.bastionDefender:
        return 'Bastion Defender';
      case DefenderType.beast:
        return 'Beast';
    }
  }
}
