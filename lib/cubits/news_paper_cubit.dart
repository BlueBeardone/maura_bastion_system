import 'package:bloc/bloc.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/test_data/news_paper/fake_news_paper_data.dart';
import 'package:maura_bastion_system/cubits/news_paper/news_paper_state.dart';

class NewsPaperCubit extends Cubit<NewsPaperMainState> {
  NewsPaperCubit() : super(InitNewsPaperState());

  Future<void> initNewsPaper() async {
    try {
      NewspaperData newspaperData = getFakeNewspaperData();
      
      emit(DisplayNewsPaperState(newspaperData: newspaperData));
    } on Exception catch (error, stackTrace) {
      emit(ErrorNewsPaperState(error: error, stackTrace: stackTrace, message: "Failed to init newspaper"));
    }
  } 
}