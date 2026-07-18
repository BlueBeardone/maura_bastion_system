import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';

class DependencyInjection {
  static void init() async {
    _registerAuthService();
    _registerBastionService();
  }

  static void _registerAuthService() {
    GetIt.I.registerLazySingleton<AuthCubit>(() => AuthCubit());
  }

  static void _registerBastionService() {
    GetIt.I.registerLazySingleton<BastionCubit>(() => BastionCubit()..loadBastions());
  }
}