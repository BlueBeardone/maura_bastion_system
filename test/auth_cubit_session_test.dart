import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockIdentityApi extends Mock implements IdentityApi {}

class MockApiClient extends Mock implements ApiClient {}

class MockAuthSessionStore extends Mock implements AuthSessionStore {}

void main() {
  late MockIdentityApi identityApi;
  late MockApiClient apiClient;
  late MockAuthSessionStore sessionStore;

  setUp(() {
    identityApi = MockIdentityApi();
    apiClient = MockApiClient();
    sessionStore = MockAuthSessionStore();
  });

  AuthCubit buildCubit() => AuthCubit(
        identityApi: identityApi,
        apiClient: apiClient,
        sessionStore: sessionStore,
      );

  test('starts in AuthLoadingState', () {
    expect(buildCubit().state, isA<AuthLoadingState>());
  });

  test('restoreSession with no stored token emits unauthenticated', () async {
    when(() => sessionStore.load()).thenAnswer((_) async => null);
    final cubit = buildCubit();

    await cubit.restoreSession();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verifyNever(() => identityApi.getMe());
  });

  test('restoreSession with valid token emits authenticated and sets client token', () async {
    when(() => sessionStore.load()).thenAnswer((_) async => 'stored-token');
    when(() => identityApi.getMe())
        .thenAnswer((_) async => User(id: 'u1', displayName: 'walter'));
    final cubit = buildCubit();

    await cubit.restoreSession();

    final state = cubit.state;
    expect(state, isA<AuthAuthenticatedState>());
    verify(() => apiClient.setAuthToken('stored-token')).called(1);
    verify(() => identityApi.getMe()).called(1);
  });

  test('restoreSession with rejected token clears store and emits unauthenticated', () async {
    when(() => sessionStore.load()).thenAnswer((_) async => 'stale-token');
    when(() => identityApi.getMe())
        .thenThrow(ApiException(statusCode: 401, message: 'expired'));
    when(() => sessionStore.clear()).thenAnswer((_) async {});
    final cubit = buildCubit();

    await cubit.restoreSession();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verify(() => sessionStore.clear()).called(1);
    verify(() => apiClient.setAuthToken(null)).called(1);
  });

  test('restoreSession with 403 clears store and emits unauthenticated', () async {
    when(() => sessionStore.load()).thenAnswer((_) async => 'forbidden-token');
    when(() => identityApi.getMe())
        .thenThrow(ApiException(statusCode: 403, message: 'forbidden'));
    when(() => sessionStore.clear()).thenAnswer((_) async {});
    final cubit = buildCubit();

    await cubit.restoreSession();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verify(() => sessionStore.clear()).called(1);
    verify(() => apiClient.setAuthToken(null)).called(1);
  });

  test('restoreSession with non-ApiException error keeps stored token', () async {
    when(() => sessionStore.load()).thenAnswer((_) async => 'stored-token');
    when(() => identityApi.getMe()).thenThrow(Exception('offline'));
    final cubit = buildCubit();

    await cubit.restoreSession();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verifyNever(() => sessionStore.clear());
    verifyNever(() => apiClient.setAuthToken(null));
  });

  test('restoreSession with throwing store emits unauthenticated without getMe', () async {
    when(() => sessionStore.load()).thenThrow(Exception('store failure'));
    final cubit = buildCubit();

    await cubit.restoreSession();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verifyNever(() => identityApi.getMe());
  });

  test('logout clears the store and client token', () async {
    when(() => sessionStore.clear()).thenAnswer((_) async {});
    final cubit = buildCubit();

    await cubit.logout();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
    verify(() => sessionStore.clear()).called(1);
    verify(() => apiClient.setAuthToken(null)).called(1);
  });
}
