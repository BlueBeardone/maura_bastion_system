import 'package:flutter/material.dart';
import 'package:maura_bastion_system/core/config/appwrite_client.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/news_paper.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: Column(
        children: [
          Expanded(child: NewspaperLayout()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => client.ping(),
              child: const Text('Send a ping'),
            ),
          ),
        ],
      ),
    );
  }
}

