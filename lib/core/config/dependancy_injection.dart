import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/health_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

class DependencyInjection {
  static void init() async {
    _registerApiClient();
    _registerApiServices();
    _registerCubits();
  }

  static void _registerApiClient() {
    GetIt.I.registerLazySingleton<ApiClient>(() => ApiClient());
  }

  static void _registerApiServices() {
    final client = GetIt.I<ApiClient>();
    GetIt.I.registerLazySingleton<HealthApi>(() => HealthApi(client: client));
    GetIt.I.registerLazySingleton<IdentityApi>(() => IdentityApi(client: client));
    GetIt.I.registerLazySingleton<BastionApi>(() => BastionApi(client: client));
    GetIt.I.registerLazySingleton<DefenderApi>(() => DefenderApi(client: client));
    GetIt.I.registerLazySingleton<FacilityApi>(() => FacilityApi(client: client));
    GetIt.I.registerLazySingleton<HirelingApi>(() => HirelingApi(client: client));
    GetIt.I.registerLazySingleton<NewspaperApi>(() => NewspaperApi(client: client));
  }

  static void _registerCubits() {
    GetIt.I.registerLazySingleton<AuthCubit>(() => AuthCubit(identityApi: GetIt.I<IdentityApi>()));
  }
}