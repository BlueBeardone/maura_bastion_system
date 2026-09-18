import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/data/chart_points_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save then read round-trips points', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ChartPointsStore();
    await store.save('b1', const ChartPoints(
      earnedPoints: 4,
      points: {EventChart.wilds: 3, EventChart.hearth: 1},
    ));

    final read = await store.read('b1');
    expect(read, {EventChart.wilds: 3, EventChart.hearth: 1});
  });

  test('read of an unknown bastion is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ChartPointsStore();
    expect(await store.read('nope'), isEmpty);
  });

  test('read ignores unknown chart names', () async {
    SharedPreferences.setMockInitialValues({
      'chart_points_b2': '{"points": {"wilds": 2, "notAChart": 5}}',
    });
    final store = ChartPointsStore();
    final read = await store.read('b2');
    expect(read, {EventChart.wilds: 2});
  });

  test('read of corrupt (non-JSON) data is empty, no throw', () async {
    SharedPreferences.setMockInitialValues({'chart_points_b1': 'not json'});
    final store = ChartPointsStore();
    expect(await store.read('b1'), isEmpty);
  });

  test('read of wrong-shaped JSON is empty, no throw', () async {
    SharedPreferences.setMockInitialValues({'chart_points_b1': '{"points": 5}'});
    final store = ChartPointsStore();
    expect(await store.read('b1'), isEmpty);
  });
}
