import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/core/config/dependancy_injection.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/login/presentation/auth_gate.dart';

void main() {
  DependencyInjection.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bastions of Maura',
      theme: mainThemeTheme,
      home: BlocProvider<AuthCubit>.value(
        value: GetIt.I<AuthCubit>(),
        child: const AuthGate(),
      ),
    );
  }
}