import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockDefenderApi extends Mock implements DefenderApi {}

class MockDiscordAnnouncer extends Mock implements DiscordAnnouncer {}

void main() {
  late MockDefenderApi api;
  late MockDiscordAnnouncer announcer;

  setUpAll(() {
    registerFallbackValue(Defender(id: '', type: DefenderType.knight, bastionId: ''));
    registerFallbackValue(<Defender>[]);
  });

  setUp(() {
    api = MockDefenderApi();
    announcer = MockDiscordAnnouncer();
    when(() => announcer.announceDefenderAcquired(any(),
        bastionName: any(named: 'bastionName'))).thenAnswer((_) async {});
    when(() => announcer.announceDefendersRecruited(any(),
        bastionName: any(named: 'bastionName'))).thenAnswer((_) async {});
  });

  DefendersCubit buildCubit() => DefendersCubit(
        bastionId: 'b1',
        defenderApi: api,
        discordAnnouncer: announcer,
        bastionName: 'Ravencrest',
      );

  test('loadDefenders emits isLoading true then false', () async {
    when(() => api.getAll()).thenAnswer((_) async => []);
    final cubit = buildCubit();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);
    await cubit.loadDefenders();
    await Future<void>.delayed(Duration.zero);
    expect(states.first.isLoading, isTrue);
    expect(states.last.isLoading, isFalse);
    await cubit.close();
  });

  test('loadDefenders filters defenders to the current bastion', () async {
    when(() => api.getAll()).thenAnswer((_) async => [
          Defender(
              id: 'd1',
              name: 'A',
              type: DefenderType.knight,
              bastionId: 'b1'),
          Defender(
              id: 'd2',
              name: 'B',
              type: DefenderType.knight,
              bastionId: 'other'),
        ]);
    final cubit = buildCubit();
    await cubit.loadDefenders();
    expect(cubit.state.defenders.map((d) => d.id), ['d1']);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('loadDefenders failure emits error and clears isLoading', () async {
    when(() => api.getAll()).thenThrow(Exception('boom'));
    final cubit = buildCubit();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);
    await cubit.loadDefenders();
    await Future<void>.delayed(Duration.zero);
    expect(states.last.error, isNotNull);
    expect(states.last.isLoading, isFalse);
    await cubit.close();
  });

  test('addDefender returns true on success, emits isMutating then list with '
      'the created defender', () async {
    final created = Defender(
        id: 'd9', name: 'Aldric', type: DefenderType.knight, bastionId: 'b1');
    when(() => api.create(any())).thenAnswer((_) async => created);
    final cubit = buildCubit();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);

    final ok = await cubit.addDefender(
      name: 'Aldric',
      type: DefenderType.knight,
      description: '',
      acquisitionStory: '',
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(states.first.isMutating, isTrue);
    expect(states.last.isMutating, isFalse);
    expect(states.last.error, isNull);
    expect(states.last.defenders.map((d) => d.id), contains('d9'));
    await cubit.close();
  });

  test('addDefender returns false and emits error on failure without adding',
      () async {
    when(() => api.create(any())).thenThrow(Exception('boom'));
    final cubit = buildCubit();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);

    final ok = await cubit.addDefender(
      name: 'Aldric',
      type: DefenderType.knight,
      description: '',
      acquisitionStory: '',
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isFalse);
    expect(states.last.isMutating, isFalse);
    expect(states.last.error, isNotNull);
    expect(states.last.defenders, isEmpty);
    await cubit.close();
  });

  test('addDefender returns false when the Discord announcement throws',
      () async {
    when(() => announcer.announceDefenderAcquired(any(),
        bastionName: any(named: 'bastionName'))).thenThrow(Exception('down'));
    when(() => api.create(any())).thenAnswer((_) async => Defender(
        id: 'd9', name: 'Aldric', type: DefenderType.knight, bastionId: 'b1'));
    final cubit = buildCubit();

    final ok = await cubit.addDefender(
      name: 'Aldric',
      type: DefenderType.knight,
      description: '',
      acquisitionStory: '',
    );

    expect(ok, isFalse);
    expect(cubit.state.error, isNotNull);
    verifyNever(() => api.create(any()));
    await cubit.close();
  });

  test('removeDefender returns true, deletes and removes from state', () async {
    when(() => api.getAll()).thenAnswer((_) async => [
          Defender(id: 'd1', name: 'A', type: DefenderType.knight, bastionId: 'b1'),
          Defender(id: 'd2', name: 'B', type: DefenderType.knight, bastionId: 'b1'),
        ]);
    when(() => api.delete(any())).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.loadDefenders();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);

    final ok = await cubit.removeDefender('d1');
    await Future<void>.delayed(Duration.zero);

    expect(ok, isTrue);
    expect(states.first.isMutating, isTrue);
    expect(states.last.isMutating, isFalse);
    expect(cubit.state.defenders.map((d) => d.id), ['d2']);
    await cubit.close();
  });

  test('removeDefender returns false and emits error on failure instead of '
      'throwing', () async {
    when(() => api.getAll()).thenAnswer((_) async => [
          Defender(id: 'd1', name: 'A', type: DefenderType.knight, bastionId: 'b1'),
        ]);
    when(() => api.delete(any())).thenThrow(Exception('boom'));
    final cubit = buildCubit();
    await cubit.loadDefenders();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);

    final ok = await cubit.removeDefender('d1');
    await Future<void>.delayed(Duration.zero);

    expect(ok, isFalse);
    expect(states.last.error, isNotNull);
    expect(states.last.isMutating, isFalse);
    expect(cubit.state.defenders.map((d) => d.id), ['d1']);
    await cubit.close();
  });

  test('bulkAddDefenders emits isMutating and returns the created count',
      () async {
    when(() => api.create(any())).thenAnswer(
      (_) async => Defender(
          id: 'new', name: 'X', type: DefenderType.knight, bastionId: 'b1'),
    );
    final cubit = buildCubit();
    final states = <DefendersState>[];
    cubit.stream.listen(states.add);

    final count = await cubit.bulkAddDefenders(
      type: DefenderType.knight,
      names: ['Aldric Vane', 'Bram Oakfist'],
      description: '',
      acquisitionStory: '',
    );
    await Future<void>.delayed(Duration.zero);

    expect(count, 2);
    expect(states.first.isMutating, isTrue);
    expect(states.last.isMutating, isFalse);
    expect(states.last.error, isNull);
    expect(cubit.state.defenders.length, 2);
    await cubit.close();
  });

  test('bulkAddDefenders creates nothing and emits error when the '
      'announcement fails', () async {
    when(() => announcer.announceDefendersRecruited(any(),
        bastionName: any(named: 'bastionName'))).thenThrow(Exception('down'));
    final cubit = buildCubit();

    final count = await cubit.bulkAddDefenders(
      type: DefenderType.knight,
      names: ['Aldric Vane'],
      description: '',
      acquisitionStory: '',
    );

    expect(count, 0);
    expect(cubit.state.error, isNotNull);
    verifyNever(() => api.create(any()));
    await cubit.close();
  });
}
