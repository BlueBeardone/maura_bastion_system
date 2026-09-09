import 'package:bloc/bloc.dart';

import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/data/default_data/news_paper/default_news_paper_data.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_state.dart';

class NewsPaperCubit extends Cubit<NewsPaperMainState> {
  final NewspaperApi _newspaperApi;

  NewsPaperCubit({required NewspaperApi newspaperApi})
      : _newspaperApi = newspaperApi,
        super(InitNewsPaperState());

  Future<void> initNewsPaper() async {
    try {
      final articles = await _newspaperApi.getAll();
      final newspapers = _buildNewspaperData(articles);

      emit(DisplayNewsPaperState(newspapers: newspapers));
    } on Exception catch (error, stackTrace) {
      emit(ErrorNewsPaperState(error: error, stackTrace: stackTrace, message: "Failed to init newspaper"));
    }
  }

  List<NewspaperData> _buildNewspaperData(List<NewspaperArticle> articles) {
    if (articles.isEmpty) return getDefaultNewspapers();

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    final date = '${now.day} ${months[now.month - 1]} ${now.year}';

    return [
      NewspaperData(
        newspaperName: 'Maura Weekly',
        date: date,
        edition: 'Vol. XLII, No. 17',
        leadArticle: articles.first,
        otherArticles: articles.length > 1 ? articles.sublist(1) : [],
      ),
    ];
  }
}