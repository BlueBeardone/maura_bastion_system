import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/features/login/logic/login_cubit.dart';

class DependencyInjection {
  static void init() async {
    _registerUserService();
  }

  static void _registerUserService()  {
    GetIt.I.registerLazySingleton<LoginCubit>(() => (LoginCubit()));
  }
}