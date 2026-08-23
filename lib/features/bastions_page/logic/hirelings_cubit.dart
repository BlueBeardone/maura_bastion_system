import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

part 'hirelings_state.dart';

class HirelingsCubit extends Cubit<HirelingsState> {
  final HirelingApi _hirelingApi;

  HirelingsCubit({
    required String bastionId,
    required HirelingApi hirelingApi,
  }) : _hirelingApi = hirelingApi,
       super(HirelingsState(bastionId: bastionId));

  Future<void> loadHirelings() async {
    try {
      final allHirelings = await _hirelingApi.getAll();
      final bastionHirelings = allHirelings.where((h) => h.bastionId == state.bastionId).toList();
      emit(state.copyWith(hirelings: bastionHirelings));
    } catch (_) {}
  }

  Future<void> addHireling({
    required String name,
    String? role,
    String? description,
    String? imgUrl,
    String? acquisitionStory,
  }) async {
    try {
      final newHireling = await _hirelingApi.create(Hireling(
        id: '',
        name: name,
        role: role,
        description: description,
        imgUrl: imgUrl,
        bastionId: state.bastionId,
        acquisitionStory: acquisitionStory,
      ));
      emit(state.copyWith(hirelings: [...state.hirelings, newHireling]));
    } catch (_) {}
  }

  Future<void> removeHireling(String id) async {
    try {
      await _hirelingApi.delete(id);
      emit(state.copyWith(
        hirelings: state.hirelings.where((h) => h.id != id).toList(),
      ));
    } catch (_) {}
  }

  Future<void> assignHireling(String hirelingId, String facilityId) async {
    try {
      final hireling = state.hirelings.firstWhere((h) => h.id == hirelingId);
      final updated = await _hirelingApi.update(hirelingId, hireling.copyWith(facilityId: facilityId));
      emit(state.copyWith(
        hirelings: state.hirelings.map((h) => h.id == hirelingId ? updated : h).toList(),
      ));
    } catch (_) {}
  }

  Future<void> dismissHireling(String hirelingId) async {
    try {
      final hireling = state.hirelings.firstWhere((h) => h.id == hirelingId);
      final updated = await _hirelingApi.update(hirelingId, hireling.copyWith(facilityId: null));
      emit(state.copyWith(
        hirelings: state.hirelings.map((h) => h.id == hirelingId ? updated : h).toList(),
      ));
    } catch (_) {}
  }
}
