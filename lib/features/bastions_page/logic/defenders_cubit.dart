import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

part 'defenders_state.dart';

class DefendersCubit extends Cubit<DefendersState> {
  final DefenderApi _defenderApi;

  DefendersCubit({
    required String bastionId,
    required DefenderApi defenderApi,
  }) : _defenderApi = defenderApi,
       super(DefendersState(bastionId: bastionId));

  Future<void> loadDefenders() async {
    try {
      final allDefenders = await _defenderApi.getAll();
      final bastionDefenders = allDefenders.where((d) => d.bastionId == state.bastionId).toList();
      emit(state.copyWith(defenders: bastionDefenders));
    } catch (_) {}
  }

  Future<void> addDefender({
    required String name,
    required DefenderType type,
    required String description,
    required String acquisitionStory,
  }) async {
    try {
      final newDefender = await _defenderApi.create(Defender(
        id: '',
        name: name,
        type: type,
        description: description,
        acquisitionStory: acquisitionStory,
        bastionId: state.bastionId,
      ));
      emit(state.copyWith(defenders: [...state.defenders, newDefender]));
    } catch (_) {}
  }
}
