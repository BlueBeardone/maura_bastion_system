import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

part 'defenders_state.dart';

class DefendersCubit extends Cubit<DefendersState> {
  final DefenderApi _defenderApi;
  final DiscordAnnouncer? _discordAnnouncer;
  final String? _bastionName;

  DefendersCubit({
    required String bastionId,
    required DefenderApi defenderApi,
    DiscordAnnouncer? discordAnnouncer,
    String? bastionName,
  })  : _defenderApi = defenderApi,
        _discordAnnouncer = discordAnnouncer,
        _bastionName = bastionName,
        super(DefendersState(bastionId: bastionId));

  Exception _asException(Object e) =>
      e is Exception ? e : Exception(e.toString());

  Future<void> loadDefenders() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final allDefenders = await _defenderApi.getAll();
      final bastionDefenders =
          allDefenders.where((d) => d.bastionId == state.bastionId).toList();
      emit(state.copyWith(
        defenders: bastionDefenders,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: _asException(e),
      ));
    }
  }

  Future<bool> addDefender({
    required String name,
    required DefenderType type,
    required String description,
    required String acquisitionStory,
  }) async {
    final newDefender = Defender(
      id: '',
      name: name,
      type: type,
      description: description,
      acquisitionStory: acquisitionStory,
      bastionId: state.bastionId,
    );
    emit(DefendersState(
      bastionId: state.bastionId,
      defenders: state.defenders,
      isMutating: true,
    ));
    try {
      await _discordAnnouncer
          ?.announceDefenderAcquired(newDefender, bastionName: _bastionName);
      final created = await _defenderApi.create(newDefender);
      emit(DefendersState(
        bastionId: state.bastionId,
        defenders: [...state.defenders, created],
      ));
      return true;
    } catch (e) {
      emit(DefendersState(
        bastionId: state.bastionId,
        defenders: state.defenders,
        error: _asException(e),
      ));
      return false;
    }
  }

  Future<int> bulkAddDefenders({
    required DefenderType type,
    required List<String> names,
    required String description,
    required String acquisitionStory,
  }) async {
    final newDefenders = names
        .map(
          (name) => Defender(
            id: '',
            name: name,
            type: type,
            description: description,
            acquisitionStory: acquisitionStory,
            bastionId: state.bastionId,
          ),
        )
        .toList();
    emit(DefendersState(
      bastionId: state.bastionId,
      defenders: state.defenders,
      isMutating: true,
    ));
    try {
      await _discordAnnouncer
          ?.announceDefendersRecruited(newDefenders, bastionName: _bastionName);
    } catch (e) {
      emit(DefendersState(
        bastionId: state.bastionId,
        defenders: state.defenders,
        error: _asException(e),
      ));
      return 0;
    }
    final created = <Defender>[];
    for (final defender in newDefenders) {
      try {
        created.add(await _defenderApi.create(defender));
      } catch (_) {}
    }
    emit(DefendersState(
      bastionId: state.bastionId,
      defenders: [...state.defenders, ...created],
    ));
    return created.length;
  }

  Future<bool> removeDefender(String id) async {
    emit(DefendersState(
      bastionId: state.bastionId,
      defenders: state.defenders,
      isMutating: true,
    ));
    try {
      await _defenderApi.delete(id);
      emit(DefendersState(
        bastionId: state.bastionId,
        defenders:
            state.defenders.where((d) => d.id != id).toList(),
      ));
      return true;
    } catch (e) {
      emit(DefendersState(
        bastionId: state.bastionId,
        defenders: state.defenders,
        error: _asException(e),
      ));
      return false;
    }
  }
}
