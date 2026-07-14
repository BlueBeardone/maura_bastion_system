import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

part 'defenders_state.dart';

class DefendersCubit extends Cubit<DefendersState> {
  DefendersCubit({
    required String bastionId,
    List<Defender> initialDefenders = const [],
  }) : super(DefendersState(bastionId: bastionId, defenders: initialDefenders));

  void addDefender({
    required String name,
    required DefenderType type,
    required String description,
    required String acquisitionStory,
  }) {
    final newDefender = Defender(
      id: 'defender_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      description: description,
      acquisitionStory: acquisitionStory,
      bastionId: state.bastionId,
    );
    emit(state.copyWith(defenders: [...state.defenders, newDefender]));
  }
}
