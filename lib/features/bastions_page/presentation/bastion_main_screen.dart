import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/error/error_widget.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class BastionMainScreen extends StatelessWidget {

  const BastionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return BlocBuilder<BastionCubit, BastionState>(
      bloc: BastionCubit()..loadBastions(),
      builder: (context, state) {

        if (state is BastionErrorState) {
          return MyErrorWidget(
            message: state.message,
            icon: Icons.error_outline,
          );
        }

        if (state is BastionLoadingState) {
          return Center(child: CircularProgressIndicator());
        } 
        
        if (state is BastionLoadedState) {
          return ListView.builder(
            itemCount: state.bastions.length,
            itemBuilder: (context, index) {
              final bastion = state.bastions[index];
              return ListTile(
                title: Text(bastion.name),
                subtitle: Text(bastion.description),
              );
            },
          );
        } 

        return Center(child: Text('Unknown state'));
      },
    );
  }
}