enum FacilityRank {
  S,
  A,
  B,
  C,
  D;

  static FacilityRank fromString(String rank) {
    switch (rank) {
      case "s": return FacilityRank.S;
      case "a": return FacilityRank.A;
      case "b": return FacilityRank.B;
      case "c": return FacilityRank.C;
      case "d": return FacilityRank.D;
      default: throw ArgumentError("Invalid rank: $rank");
    }
  }
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