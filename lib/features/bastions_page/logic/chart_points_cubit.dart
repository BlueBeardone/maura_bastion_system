import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

part 'chart_points_state.dart';

class ChartPointsCubit extends Cubit<ChartPointsState> {
  ChartPointsCubit() : super(const ChartPointsState());

  void load(Bastion bastion) {
    emit(ChartPointsState(
      bastionId: bastion.id,
      points: ChartPoints(
        earnedPoints: bastion.facilities.length.clamp(0, ChartPoints.maxPoints),
      ),
    ));
  }

  void assign(EventChart chart, int delta) {
    final next = state.points.assign(chart, delta);
    if (!identical(next, state.points)) {
      emit(ChartPointsState(bastionId: state.bastionId, points: next));
    }
  }
}
