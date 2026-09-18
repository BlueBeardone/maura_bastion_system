import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/chart_web_panel.dart';

Widget harness({required ChartPointsCubit cubit}) => MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const ChartWebPanel(),
      ),
    );

// Local helper: a Bastion with [count] minimal facilities.
Bastion _bastion(int count) => Bastion(
      id: 'b1',
      name: 'Test',
      description: '',
      facilities: List.generate(
        count,
        (i) => Facility(
          id: 'f$i',
          name: 'F$i',
          rank: Rank.D,
          description: '',
        ),
      ),
      defenders: [
        Defender(id: 'd1', type: DefenderType.bastionDefender, bastionId: 'b1'),
      ],
    );

void main() {
  testWidgets('shows all six charts and the points header', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(6));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('The Chart Web'), findsOneWidget);
    expect(find.textContaining('The Wilds'), findsOneWidget);
    expect(find.textContaining('The Arcane'), findsOneWidget);
    expect(find.text('6 of 6 points unassigned'), findsOneWidget);
    expect(find.text('never fires'), findsNWidgets(6));
  });

  testWidgets('plus button assigns a point and preview updates',
      (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(2));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(cubit.state.points[EventChart.wilds], 1);
    expect(find.text('1 of 2 points unassigned'), findsOneWidget);
    expect(find.textContaining('rolls 1'), findsOneWidget);
    expect(find.textContaining('Basic'), findsWidgets);
  });

  testWidgets('minus button unassigns and clamps at zero', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(1));
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 1);
    expect(tester.widgetList(find.byIcon(Icons.add).first), isNotNull);

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 0);

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(cubit.state.points[EventChart.wilds], 0);
  });

  testWidgets('shows convergence hint when unlocked', (tester) async {
    final cubit = ChartPointsCubit();
    cubit.load(_bastion(16));
    cubit.assign(EventChart.wilds, 4);
    cubit.assign(EventChart.deeps, 4);
    cubit.assign(EventChart.hearth, 4);
    await tester.pumpWidget(harness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.textContaining('Convergence'), findsOneWidget);
  });
}
