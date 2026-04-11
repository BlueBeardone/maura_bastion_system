enum FacilitySize {
  cramped,
  roomy,
  vast
}

extension MainNavigationExtension on FacilitySize {
  String get title {
    switch (this) {
      case FacilitySize.cramped: return "Cramped";
      case FacilitySize.roomy: return "Roomy";
      case FacilitySize.vast: return "Vast";
    }
  }
}