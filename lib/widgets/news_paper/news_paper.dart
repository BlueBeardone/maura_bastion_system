

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/cubits/news_paper/news_paper_cubit.dart';
import 'package:maura_bastion_system/cubits/news_paper/news_paper_state.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/widgets/error/error_widget.dart';
import 'package:maura_bastion_system/widgets/news_paper/articles/main_news_article.dart';
import 'package:maura_bastion_system/widgets/news_paper/articles/news_article.dart';
import 'package:maura_bastion_system/widgets/news_paper/articles/news_paper_title.dart';

class NewspaperLayout extends StatelessWidget {

  const NewspaperLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsPaperCubit, NewsPaperMainState>(
      bloc: NewsPaperCubit()..initNewsPaper(),
      builder: (context, state) {
        if (state is DisplayNewsPaperState) {
          return _displayNewsPaper(context, state);
        }

        if (state is ErrorNewsPaperState) {
          return MyErrorWidget(message: state.message,);
        }

        return SizedBox();
      },
    );
  }

  Widget _displayNewsPaper(BuildContext context, DisplayNewsPaperState state) {
    return Scaffold(
          backgroundColor: Theme.of(context).primaryColorDark, // dark surrounding area
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200), // classic broadsheet width
              color: Theme.of(context).scaffoldBackgroundColor, // aged paper
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NewsPaperTitle(newspaperData: state.newspaperData,),
                    Divider(thickness: 2),
                    const SizedBox(height: 16),
                    MainNewsArticle(article: state.newspaperData.leadArticle),
                    const SizedBox(height: 24),
                    _buildSecondaryArticles(state.newspaperData.otherArticles),
                    const SizedBox(height: 32),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildSecondaryArticles(List<NewspaperArticle> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 800, // fixed height for each article card
          ),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return NewsArticle(article: article,);
          },
        );
      },
    );
  }

  // ------------------- Footer (simple line & mock advertisement) -------------------
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Divider(thickness: 2),
        const SizedBox(height: 16),
        Text(
          '“THE MOST RELIABLE NEWS IN THE CITY”',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Published. Offices at Guild of Maura Street, Maura.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}