import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';

class NewsPaperTitle extends StatelessWidget {

  final NewspaperData newspaperData;

  const NewsPaperTitle({
    super.key, 
    required this.newspaperData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          newspaperData.newspaperName.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(newspaperData.date),
          ],
        ),
        const SizedBox(height: 8),
        Divider(thickness: 2),
        const SizedBox(height: 8),
        Text(
          '“ALL THE NEWS THAT`S FIT TO PRINT”',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}