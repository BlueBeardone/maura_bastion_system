import 'package:equatable/equatable.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_data.dart';

abstract class NewsPaperMainState extends Equatable {
  const NewsPaperMainState();
}

class NewsPaperState extends NewsPaperMainState {
  @override
  List<Object?> get props => [];
}

class InitNewsPaperState extends NewsPaperMainState {
  @override
  List<Object?> get props => [];
}

class DisplayNewsPaperState extends NewsPaperMainState {
  final NewspaperData newspaperData;

  const DisplayNewsPaperState({required this.newspaperData});
  
  @override
  List<Object?> get props => [];
}

class ErrorNewsPaperState extends NewsPaperMainState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const ErrorNewsPaperState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => throw UnimplementedError();
}

