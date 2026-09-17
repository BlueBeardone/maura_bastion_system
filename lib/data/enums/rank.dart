enum Rank {
  S,
  A,
  B,
  C,
  D,
  E;

  static Rank fromString(String rank) {
    switch (rank) {
      case "s": return Rank.S;
      case "a": return Rank.A;
      case "b": return Rank.B;
      case "c": return Rank.C;
      case "d": return Rank.D;
      case "e": return Rank.E;
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
      case Rank.E: return "E";
    }
  }

  Rank? get next {
    switch (this) {
      case Rank.D: return Rank.C;
      case Rank.C: return Rank.B;
      case Rank.B: return Rank.A;
      case Rank.A: return Rank.S;
      case Rank.S: return null;
      case Rank.E: return Rank.D;
    }
  }
}