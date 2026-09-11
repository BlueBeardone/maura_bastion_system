import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/health_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

class DependencyInjection {
  static Future<void> init() async {
    GetIt.I.registerLazySingleton<AuthSessionStore>(() => AuthSessionStore());
    _registerApiClient();
    _registerApiServices();
    _registerCubits();
  }

  static void _registerApiClient() {
    GetIt.I
        .registerLazySingleton<ApiClient>(() => ApiClient(sessionStore: GetIt.I<AuthSessionStore>()));
  }

  static void _registerApiServices() {
    final client = GetIt.I<ApiClient>();
    GetIt.I.registerLazySingleton<HealthApi>(() => HealthApi(client: client));
    GetIt.I.registerLazySingleton<IdentityApi>(
        () => IdentityApi(client: client, sessionStore: GetIt.I<AuthSessionStore>()));
    GetIt.I.registerLazySingleton<BastionApi>(() => BastionApi(client: client));
    GetIt.I.registerLazySingleton<DefenderApi>(() => DefenderApi(client: client));
    GetIt.I.registerLazySingleton<DiscordApi>(() => DiscordApi(client: client));
    GetIt.I.registerLazySingleton<DiscordAnnouncer>(
        () => DiscordAnnouncer(discordApi: GetIt.I<DiscordApi>()));
    GetIt.I.registerLazySingleton<FacilityApi>(() => FacilityApi(client: client));
    GetIt.I.registerLazySingleton<HirelingApi>(() => HirelingApi(client: client));
    GetIt.I.registerLazySingleton<NewspaperApi>(() => NewspaperApi(client: client));
  }

  static void _registerCubits() {
    GetIt.I.registerLazySingleton<AuthCubit>(() => AuthCubit(
          identityApi: GetIt.I<IdentityApi>(),
          apiClient: GetIt.I<ApiClient>(),
          sessionStore: GetIt.I<AuthSessionStore>(),
        ));
  }
}
