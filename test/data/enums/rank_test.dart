import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';

void main() {
  group('Rank.next', () {
    test('advances through the chain and stops at S', () {
      expect(Rank.D.next, Rank.C);
      expect(Rank.C.next, Rank.B);
      expect(Rank.B.next, Rank.A);
      expect(Rank.A.next, Rank.S);
      expect(Rank.S.next, isNull);
    });
  });
}
