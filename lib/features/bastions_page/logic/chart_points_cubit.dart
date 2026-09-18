import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_points.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/data/chart_points_store.dart';

part 'chart_points_state.dart';

class ChartPointsCubit extends Cubit<ChartPointsState> {
  ChartPointsCubit({ChartPointsStore? store}) : _store = store ?? ChartPointsStore(), super(const ChartPointsState());

  final ChartPointsStore _store;

  void load(Bastion bastion) {
    emit(ChartPointsState(
      bastionId: bastion.id,
      points: ChartPoints(
        earnedPoints: bastion.facilities.length.clamp(0, ChartPoints.maxPoints),
      ),
    ));
    unawaited(_restore(bastion.id));
  }

  void assign(EventChart chart, int delta) {
    final next = state.points.assign(chart, delta);
    if (!identical(next, state.points)) {
      emit(ChartPointsState(bastionId: state.bastionId, points: next));
      if (state.bastionId != null) {
        unawaited(_store.save(state.bastionId!, state.points));
      }
    }
  }

  Future<void> _restore(String bastionId) async {
    final stored = await _store.read(bastionId);
    if (stored.isEmpty || bastionId != state.bastionId) return;
    // Only restore while no user assignment has happened since load, so a
    // concurrent assign (M1) isn't clobbered by the in-flight restore.
    if (state.points.assignedTotal != 0) return;
    final restored = ChartPoints(
      earnedPoints: state.points.earnedPoints,
      points: stored,
    );
    emit(ChartPointsState(bastionId: state.bastionId, points: restored));
  }
}
