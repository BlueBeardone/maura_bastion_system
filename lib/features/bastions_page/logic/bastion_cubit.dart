import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/test_data/bastion/fake_bastion_data.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  BastionCubit() : super(BastionLoadingState());

  Future<void> loadBastions() async {
    try {
      await Future.delayed(Duration(seconds: 2));
      final bastions = getFakeBastions();
      emit(BastionLoadedState(bastions: bastions));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to load bastions'));
    }
  }

  void addFacility(String bastionId, Facility facility) {
    if (state is! BastionLoadedState) return;
    final loaded = state as BastionLoadedState;
    final bastions = List<Bastion>.from(loaded.bastions);

    final index = bastions.indexWhere((b) => b.id == bastionId);
    if (index == -1) return;

    final bastion = bastions[index];
    final facilityWithConstruction = Facility(
      id: facility.id,
      name: facility.name,
      rank: facility.rank,
      description: facility.description,
      imgUrl: facility.imgUrl,
      table: facility.table,
      minimumRequiredHirelings: facility.minimumRequiredHirelings,
      constructionTurns: facility.constructionTurns,
      cost: facility.cost,
      constructedTurns: facility.constructionTurns,
    );
    final updatedFacilities = [...bastion.facilities, facilityWithConstruction];

    bastions[index] = Bastion(
      id: bastion.id,
      name: bastion.name,
      description: bastion.description,
      imgUrl: bastion.imgUrl,
      facilities: updatedFacilities,
      defenders: bastion.defenders,
      hirelings: bastion.hirelings,
    );

    emit(BastionLoadedState(bastions: bastions));
  }

  void createBastion(
    String name,
    String description,
    String? imgUrl,
    List<Facility> facilities,
  ) {
    if (state is! BastionLoadedState) return;
    final loaded = state as BastionLoadedState;
    final bastions = List<Bastion>.from(loaded.bastions);

    final id = 'bastion_${DateTime.now().millisecondsSinceEpoch}';
    final builtFacilities = facilities.map((f) => Facility(
      id: f.id,
      name: f.name,
      rank: f.rank,
      description: f.description,
      imgUrl: f.imgUrl,
      table: f.table,
      minimumRequiredHirelings: f.minimumRequiredHirelings,
      constructionTurns: f.constructionTurns,
      cost: f.cost,
      constructedTurns: 0,
    )).toList();

    bastions.add(Bastion(
      id: id,
      name: name,
      description: description,
      imgUrl: imgUrl,
      facilities: builtFacilities,
      hirelings: getDefaultUserHirelings(id),
    ));

    emit(BastionLoadedState(bastions: bastions));
  }
}