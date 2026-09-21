import 'package:bloc/bloc.dart';

import 'package:maura_bastion_system/api/newspaper_api.dart';
import 'package:maura_bastion_system/data/default_data/news_paper/default_news_paper_data.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/features/bastions_page/data/filler_store.dart';
import 'package:maura_bastion_system/features/news_paper/logic/news_paper_state.dart';

class NewsPaperCubit extends Cubit<NewsPaperMainState> {
  final NewspaperApi _newspaperApi;
  final FillerStore? _fillerStore;

  NewsPaperCubit({required NewspaperApi newspaperApi, FillerStore? fillerStore})
      : _newspaperApi = newspaperApi,
        _fillerStore = fillerStore,
        super(InitNewsPaperState());

  Future<void> initNewsPaper() async {
    try {
      final articles = await _newspaperApi.getAll();
      final fillers = await _loadFillers();

      emit(DisplayNewsPaperState(newspapers: _buildNewspaperData(articles, fillers)));
    } on Exception catch (error, stackTrace) {
      emit(ErrorNewsPaperState(error: error, stackTrace: stackTrace, message: "Failed to init newspaper"));
    }
  }

  Future<List<NewspaperArticle>> _loadFillers() async {
    final store = _fillerStore;
    if (store == null) return const [];
    try {
      // Store order is oldest→newest; display wants latest first.
      return (await store.readAll()).reversed.toList();
    } catch (_) {
      return const [];
    }
  }

  List<NewspaperData> _buildNewspaperData(
    List<NewspaperArticle> articles,
    List<NewspaperArticle> fillers,
  ) {
    if (articles.isEmpty && fillers.isEmpty) return getDefaultNewspapers();

    final edition = [...articles];
    if (edition.length < 3) {
      edition.addAll(fillers.take(3 - edition.length));
    }

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
        leadArticle: edition.first,
        otherArticles: edition.length > 1 ? edition.sublist(1) : [],
      ),
    ];
  }
}
