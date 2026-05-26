import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/config/dependancy_injection.dart';
import 'package:maura_bastion_system/core/themes/main_theme.dart';
import 'package:maura_bastion_system/features/main_menu/main_page.dart';

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
      home: MainPage(),
    );
  }
}