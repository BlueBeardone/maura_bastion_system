import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  final BastionApi _bastionApi;
  final FacilityApi _facilityApi;

  BastionCubit({required BastionApi bastionApi, required FacilityApi facilityApi})
      : _bastionApi = bastionApi,
        _facilityApi = facilityApi,
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
    try {
      await _facilityApi.create(facility, bastionId);
      await loadBastions();
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

        final bastions = state is BastionLoadedState
          ? List<Bastion>.from((state as BastionLoadedState).bastions)
          : <Bastion>[];
        bastions.add(newBastion);
      emit(BastionLoadedState(bastions: bastions));
      return newBastion;
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to create bastion'));
      return null;
    }
  }
}