import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockHirelingApi extends Mock implements HirelingApi {}

void main() {
  late MockHirelingApi api;

  setUpAll(() {
    registerFallbackValue(Hireling(id: '', name: '', bastionId: ''));
  });

  setUp(() {
    api = MockHirelingApi();
  });

  HirelingsCubit buildCubit() =>
      HirelingsCubit(bastionId: 'b1', hirelingApi: api);

  test('loadHirelings emits isLoading true then false', () async {
    when(() => api.getAll()).thenAnswer((_) async => []);
    final cubit = buildCubit();
    final states = <HirelingsState>[];
    cubit.stream.listen(states.add);
    await cubit.loadHirelings();
    await Future<void>.delayed(Duration.zero);
    expect(states.first.isLoading, isTrue);
    expect(states.last.isLoading, isFalse);
  });

  test('loadHirelings failure emits error', () async {
    when(() => api.getAll()).thenThrow(Exception('boom'));
    final cubit = buildCubit();
    final states = <HirelingsState>[];
    cubit.stream.listen(states.add);
    await cubit.loadHirelings();
    await Future<void>.delayed(Duration.zero);
    expect(states.last.error, isNotNull);
    expect(states.last.isLoading, isFalse);
  });

  test('addHireling returns true on success and false on failure', () async {
    final created = Hireling(
      id: 'h1',
      name: 'Sara',
      bastionId: 'b1',
    );
    when(() => api.create(any())).thenAnswer((_) async => created);
    final cubit = buildCubit();
    final states = <HirelingsState>[];
    cubit.stream.listen(states.add);
    final ok = await cubit.addHireling(name: 'Sara');
    await Future<void>.delayed(Duration.zero);
    expect(ok, isTrue);
    expect(states.last.isMutating, isFalse);

    when(() => api.create(any())).thenThrow(Exception('boom'));
    final ok2 = await cubit.addHireling(name: 'S2');
    await Future<void>.delayed(Duration.zero);
    expect(ok2, isFalse);
    expect(states.last.error, isNotNull);
  });

  test('assignHireling returns false and emits error on failure', () async {
    final existing = Hireling(id: 'h1', name: 'Sara', bastionId: 'b1');
    when(() => api.getAll()).thenAnswer((_) async => [existing]);
    final cubit = buildCubit();
    await cubit.loadHirelings();
    final states = <HirelingsState>[];
    cubit.stream.listen(states.add);
    when(() => api.update(any(), any())).thenThrow(Exception('boom'));
    final ok = await cubit.assignHireling('h1', 'f1');
    await Future<void>.delayed(Duration.zero);
    expect(ok, isFalse);
    expect(states.last.isMutating, isFalse);
    expect(states.last.error, isNotNull);
  });
}
