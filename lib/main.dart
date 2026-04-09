import 'package:flutter/material.dart';
import 'package:maura_bastion_system/themes/main_theme.dart';
import 'package:maura_bastion_system/widgets/entry_page/main_page.dart';

void main() {
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