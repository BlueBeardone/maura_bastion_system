import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

part 'hirelings_state.dart';

class HirelingsCubit extends Cubit<HirelingsState> {
  HirelingsCubit({
    required String bastionId,
    List<Hireling> initialHirelings = const [],
  }) : super(HirelingsState(bastionId: bastionId, hirelings: initialHirelings));

  void addHireling({
    required String name,
    String? role,
    String? description,
    String? imgUrl,
  }) {
    final newHireling = Hireling(
      id: 'hireling_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: role,
      description: description,
      imgUrl: imgUrl,
      bastionId: state.bastionId,
    );
    emit(state.copyWith(hirelings: [...state.hirelings, newHireling]));
  }

  void removeHireling(String id) {
    emit(state.copyWith(
      hirelings: state.hirelings.where((h) => h.id != id).toList(),
    ));
  }
}
