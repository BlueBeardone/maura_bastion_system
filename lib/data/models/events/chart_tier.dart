import 'package:maura_bastion_system/data/enums/rank.dart';

enum ChartTier {
  basic,
  skilled,
  master,
  legend;

  /// Maps a points value to its tier. Values above the 16-point maximum
  /// (see [legend.maxPoints]) are clamped to [legend]; the caller — the
  /// future points model — validates the 16-point cap.
  static ChartTier? forPoints(int points) {
    if (points <= 0) return null;
    if (points <= 3) return basic;
    if (points <= 7) return skilled;
    if (points <= 12) return master;
    return legend;
  }

  /// Best reward rank this tier may roll. Rank-null materials (metals,
  /// creature parts, ...) are harvested at this rank.
  Rank get rewardRankCap {
    switch (this) {
      case basic:
        return Rank.D;
      case skilled:
        return Rank.B;
      case master:
        return Rank.A;
      case legend:
        return Rank.S;
    }
  }

  int get minPoints {
    switch (this) {
      case basic:
        return 1;
      case skilled:
        return 4;
      case master:
        return 8;
      case legend:
        return 13;
    }
  }

  int get maxPoints {
    switch (this) {
      case basic:
        return 3;
      case skilled:
        return 7;
      case master:
        return 12;
      case legend:
        return 16;
    }
  }
}
