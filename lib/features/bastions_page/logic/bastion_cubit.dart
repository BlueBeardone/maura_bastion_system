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
}