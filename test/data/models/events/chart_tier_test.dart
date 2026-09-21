import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  test('forPoints maps tier thresholds', () {
    expect(ChartTier.forPoints(0), isNull);
    expect(ChartTier.forPoints(-2), isNull);
    expect(ChartTier.forPoints(1), ChartTier.basic);
    expect(ChartTier.forPoints(3), ChartTier.basic);
    expect(ChartTier.forPoints(4), ChartTier.skilled);
    expect(ChartTier.forPoints(7), ChartTier.skilled);
    expect(ChartTier.forPoints(8), ChartTier.master);
    expect(ChartTier.forPoints(12), ChartTier.master);
    expect(ChartTier.forPoints(13), ChartTier.legend);
    expect(ChartTier.forPoints(16), ChartTier.legend);
  });

  test('reward rank caps per spec', () {
    expect(ChartTier.basic.rewardRankCap, Rank.D);
    expect(ChartTier.skilled.rewardRankCap, Rank.B);
    expect(ChartTier.master.rewardRankCap, Rank.A);
    expect(ChartTier.legend.rewardRankCap, Rank.S);
  });

  test('point ranges are contiguous 1..16', () {
    expect(ChartTier.basic.minPoints, 1);
    expect(ChartTier.basic.maxPoints, 3);
    expect(ChartTier.skilled.minPoints, 4);
    expect(ChartTier.skilled.maxPoints, 7);
    expect(ChartTier.master.minPoints, 8);
    expect(ChartTier.master.maxPoints, 12);
    expect(ChartTier.legend.minPoints, 13);
    expect(ChartTier.legend.maxPoints, 16);
  });
}
