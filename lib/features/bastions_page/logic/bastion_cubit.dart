import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
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
}