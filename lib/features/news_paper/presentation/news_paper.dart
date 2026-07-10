import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_cubit.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_state.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/newspaper_page.dart';

class NewspaperLayout extends StatelessWidget {
  const NewspaperLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsPaperCubit, NewsPaperMainState>(
      bloc: NewsPaperCubit()..initNewsPaper(),
      builder: (context, state) {
        if (state is DisplayNewsPaperState) {
          return _displayNewspapers(context, state);
        }

        if (state is ErrorNewsPaperState) {
          return MyErrorWidget(message: state.message);
        }

        return const SizedBox();
      },
    );
  }

  Widget _displayNewspapers(BuildContext context, DisplayNewsPaperState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final newspaperWidth = screenWidth > 1100
        ? (screenWidth - 48) / 2
        : screenWidth - 32;

    return Scaffold(
      backgroundColor: MedievalColors.leatherDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: state.newspapers.map((np) {
              return SizedBox(
                width: newspaperWidth,
                child: NewspaperPage(newspaperData: np),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}