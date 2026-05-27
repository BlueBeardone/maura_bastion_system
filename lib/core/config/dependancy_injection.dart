import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

class DependencyInjection {
  static void init() async {
    _registerAuthService();
  }

  static void _registerAuthService() {
    GetIt.I.registerLazySingleton<AuthCubit>(() => AuthCubit());
  }
}