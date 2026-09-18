import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Bastion bastionWithFacilities(int count) => Bastion(
      id: 'b1',
      name: 'Test',
      description: '',
      facilities: List.generate(
        count,
        (i) => Facility(
          id: 'f$i',
          name: 'F$i',
          rank: Rank.D,
          description: '',
        ),
      ),
      defenders: [
        Defender(id: 'd1', type: DefenderType.bastionDefender, bastionId: 'b1'),
      ],
    );

void main() {
  late ChartPointsCubit cubit;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    cubit = ChartPointsCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state is empty', () {
    expect(cubit.state.bastionId, isNull);
    expect(cubit.state.points.earnedPoints, 0);
  });

  test('load derives earned points from facilities, capped at 16', () {
    cubit.load(bastionWithFacilities(3));
    expect(cubit.state.bastionId, 'b1');
    expect(cubit.state.points.earnedPoints, 3);

    cubit.load(bastionWithFacilities(20));
    expect(cubit.state.points.earnedPoints, ChartPoints.maxPoints);
  });

  test('assign updates points within the loaded budget', () {
    cubit.load(bastionWithFacilities(3));
    cubit.assign(EventChart.wilds, 3);
    expect(cubit.state.points[EventChart.wilds], 3);
    cubit.assign(EventChart.wilds, 1);
    expect(cubit.state.points[EventChart.wilds], 3);
    cubit.assign(EventChart.wilds, -1);
    expect(cubit.state.points[EventChart.wilds], 2);
  });

  test('loading a different bastion resets the allocation', () {
    cubit.load(bastionWithFacilities(4));
    cubit.assign(EventChart.wilds, 4);
    cubit.load(bastionWithFacilities(2));
    expect(cubit.state.points.assignedTotal, 0);
    expect(cubit.state.points.earnedPoints, 2);
  });

  test('load restores persisted points for the same bastion', () async {
    SharedPreferences.setMockInitialValues({
      'chart_points_b1': '{"points": {"wilds": 3}}',
    });
    final restoring = ChartPointsCubit();
    restoring.load(bastionWithFacilities(4));
    await Future<void>.delayed(Duration.zero);
    expect(restoring.state.points[EventChart.wilds], 3);
    expect(restoring.state.points.earnedPoints, 4);
    await restoring.close();
  });

  test('assign writes through to the store', () async {
    SharedPreferences.setMockInitialValues({});
    cubit.load(bastionWithFacilities(4));
    cubit.assign(EventChart.wilds, 2);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('chart_points_b1'), contains('wilds'));
  });
}
