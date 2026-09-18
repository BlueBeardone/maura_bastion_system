part of 'chart_points_cubit.dart';

class ChartPointsState extends Equatable {
  final String? bastionId;
  final ChartPoints points;

  const ChartPointsState({
    this.bastionId,
    this.points = const ChartPoints(earnedPoints: 0),
  });

  @override
  List<Object?> get props => [bastionId, points];
}
