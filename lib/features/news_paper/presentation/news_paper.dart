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
    return Scaffold(
      backgroundColor: MedievalColors.leatherDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: state.newspapers.map((np) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NewspaperPage(newspaperData: np),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}