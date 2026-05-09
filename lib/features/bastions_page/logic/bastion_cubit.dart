import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  BastionCubit() : super(BastionLoadingState());

  Future<void> loadBastions() async {
    try {
      await Future.delayed(Duration(seconds: 2));
      final bastions = [
        Bastion(
          id: '1',
          description: 'A sturdy bastion',
          facilities: [
            Facility(
              id: '1',
              name: 'Armory',
              rank: Rank.A,
              hirelingAmount: 10,
              description: 'A place to store weapons and armor',
              table: null,
            ),
          ],
          name: 'Castle Bastion',
          imgUrl: 'https://example.com/castle_bastion.jpg',
        ),
      ];
      emit(BastionLoadedState(bastions: bastions));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to load bastions'));
    }
  }
}