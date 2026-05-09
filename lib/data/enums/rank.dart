enum Rank {
  S,
  A,
  B,
  C,
  D;

  static Rank fromString(String rank) {
    switch (rank) {
      case "s": return Rank.S;
      case "a": return Rank.A;
      case "b": return Rank.B;
      case "c": return Rank.C;
      case "d": return Rank.D;
      default: throw ArgumentError("Invalid rank: $rank");
    }
  }
}

extension MainNavigationExtension on Rank {
  String get title {
    switch (this) {
      case Rank.S: return "S";
      case Rank.A: return "A";
      case Rank.B: return "B";
      case Rank.C: return "C";
      case Rank.D: return "D";
    }
  }
}