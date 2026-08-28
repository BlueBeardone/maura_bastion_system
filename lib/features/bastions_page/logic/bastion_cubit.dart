import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  final BastionApi _bastionApi;

  BastionCubit({required BastionApi bastionApi})
      : _bastionApi = bastionApi,
        super(BastionLoadingState());

  Future<void> loadBastions() async {
    try {
      final bastions = await _bastionApi.getAll();
      emit(BastionLoadedState(bastions: bastions));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to load bastions'));
    }
  }

  Future<void> addFacility(String bastionId, Facility facility) async {
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

    final updatedBastion = Bastion(
      id: bastion.id,
      userId: bastion.userId,
      name: bastion.name,
      description: bastion.description,
      imgUrl: bastion.imgUrl,
      facilities: updatedFacilities,
      defenders: bastion.defenders,
      hirelings: bastion.hirelings,
    );

    try {
      await _bastionApi.update(bastionId, updatedBastion);
      bastions[index] = updatedBastion;
      emit(BastionLoadedState(bastions: bastions));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to add facility'));
    }
  }

  Future<Bastion?> createBastion(
    String name,
    String description,
    String? imgUrl,
    List<Facility> facilities,
  ) async {
    if (state is! BastionLoadedState) return null;
    final loaded = state as BastionLoadedState;

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

    try {
      final newBastion = await _bastionApi.create(Bastion(
        id: '',
        name: name,
        description: description,
        imgUrl: imgUrl,
        facilities: builtFacilities,
      ));

      final bastions = List<Bastion>.from(loaded.bastions);
      bastions.add(newBastion);
      emit(BastionLoadedState(bastions: bastions));
      return newBastion;
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to create bastion'));
      return null;
    }
  }
}