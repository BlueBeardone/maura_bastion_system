enum FacilityRank {
  S,
  A,
  B,
  C,
  D
}

extension MainNavigationExtension on FacilityRank {
  String get title {
    switch (this) {
      case FacilityRank.S: return "S";
      case FacilityRank.A: return "A";
      case FacilityRank.B: return "B";
      case FacilityRank.C: return "C";
      case FacilityRank.D: return "D";
    }
  }
}