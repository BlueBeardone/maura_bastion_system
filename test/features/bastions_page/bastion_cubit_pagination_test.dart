import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_page.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockBastionApi extends Mock implements BastionApi {}

class MockFacilityApi extends Mock implements FacilityApi {}

Bastion bastion(String id) => Bastion(
      id: id,
      name: 'B$id',
      description: 'D',
      facilities: [],
    );

void main() {
  late MockBastionApi api;

  setUp(() {
    api = MockBastionApi();
  });

  BastionCubit buildCubit() => BastionCubit(
        bastionApi: api,
        facilityApi: MockFacilityApi(),
      );

  test('loadBastions emits loaded state with user bastion and page 1', () async {
    when(() => api.getMine()).thenAnswer((_) async => [bastion('mine-1')]);
    when(() => api.browse(page: 1)).thenAnswer((_) async => const BastionPage(
          bastions: [],
          page: 1,
          limit: 20,
          total: 22,
          hasMore: true,
        ));

    final cubit = buildCubit();
    await cubit.loadBastions();

    final state = cubit.state as BastionLoadedState;
    expect(state.userBastion!.id, 'mine-1');
    expect(state.currentPage, 1);
    expect(state.hasMore, isTrue);
    expect(state.isLoadingMore, isFalse);
  });

  test('loadBastions with no own bastion leaves userBastion null', () async {
    when(() => api.getMine()).thenAnswer((_) async => []);
    when(() => api.browse(page: 1)).thenAnswer((_) async => const BastionPage(
          bastions: [],
          page: 1,
          limit: 20,
          total: 0,
          hasMore: false,
        ));

    final cubit = buildCubit();
    await cubit.loadBastions();

    final state = cubit.state as BastionLoadedState;
    expect(state.userBastion, isNull);
    expect(state.hasMore, isFalse);
  });

  test('loadMore appends the next page and updates currentPage', () async {
    when(() => api.getMine()).thenAnswer((_) async => []);
    when(() => api.browse(page: 1)).thenAnswer((_) async => BastionPage(
          bastions: [bastion('b-1')],
          page: 1,
          limit: 1,
          total: 2,
          hasMore: true,
        ));
    when(() => api.browse(page: 2)).thenAnswer((_) async => BastionPage(
          bastions: [bastion('b-2')],
          page: 2,
          limit: 1,
          total: 2,
          hasMore: false,
        ));

    final cubit = buildCubit();
    await cubit.loadBastions();
    await cubit.loadMore();

    final state = cubit.state as BastionLoadedState;
    expect(state.browseBastions.map((b) => b.id), ['b-1', 'b-2']);
    expect(state.currentPage, 2);
    expect(state.hasMore, isFalse);
  });

  test('loadMore does nothing when hasMore is false', () async {
    when(() => api.getMine()).thenAnswer((_) async => []);
    when(() => api.browse(page: 1)).thenAnswer((_) async => const BastionPage(
          bastions: [],
          page: 1,
          limit: 20,
          total: 0,
          hasMore: false,
        ));

    final cubit = buildCubit();
    await cubit.loadBastions();
    await cubit.loadMore();

    verifyNever(() => api.browse(page: 2));
  });

  test('loadMore failure sets loadMoreFailed and keeps loaded bastions', () async {
    when(() => api.getMine()).thenAnswer((_) async => []);
    when(() => api.browse(page: 1)).thenAnswer((_) async => BastionPage(
          bastions: [bastion('b-1')],
          page: 1,
          limit: 20,
          total: 30,
          hasMore: true,
        ));
    when(() => api.browse(page: 2)).thenThrow(Exception('network down'));

    final cubit = buildCubit();
    await cubit.loadBastions();
    await cubit.loadMore();

    final state = cubit.state as BastionLoadedState;
    expect(state.loadMoreFailed, isTrue);
    expect(state.isLoadingMore, isFalse);
    expect(state.browseBastions.map((b) => b.id), ['b-1']);
  });

  test('refreshUserBastion updates the user bastion without resetting pages', () async {
    when(() => api.getMine()).thenAnswer((_) async => [bastion('mine-1')]);
    when(() => api.browse(page: 1)).thenAnswer((_) async => const BastionPage(
          bastions: [],
          page: 1,
          limit: 20,
          total: 0,
          hasMore: false,
        ));

    final cubit = buildCubit();
    await cubit.loadBastions();

    when(() => api.getMine()).thenAnswer((_) async => [bastion('mine-1-v2')]);
    await cubit.refreshUserBastion();

    final state = cubit.state as BastionLoadedState;
    expect(state.userBastion!.id, 'mine-1-v2');
    expect(state.currentPage, 1);
  });
}
