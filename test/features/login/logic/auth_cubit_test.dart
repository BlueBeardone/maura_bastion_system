import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class _RecordingIdentityApi extends IdentityApi {
  _RecordingIdentityApi(ApiClient client) : super(client: client);

  final List<LoginRequest> requests = [];

  @override
  Future<User> login(LoginRequest request) async {
    requests.add(request);
    return User(id: '1', displayName: 'Admin');
  }
}

void main() {
  late AuthCubit cubit;

  setUp(() {
    final api = _RecordingIdentityApi(ApiClient());
    cubit = AuthCubit(identityApi: api);
  });

  tearDown(() => cubit.close());

  test('emits error for empty username', () async {
    final states = <AuthState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.login('   ', 'secret');
    await pumpEventQueue();
    sub.cancel();

    final errorStates = states.whereType<AuthErrorState>();
    expect(errorStates, isNotEmpty);
    expect(errorStates.single.message, 'Username and password are required.');
  });
}