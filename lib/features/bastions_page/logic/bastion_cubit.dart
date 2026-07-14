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
    final updatedFacilities = [...bastion.facilities, facility];

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