import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/bastion_inventory.dart';
import 'package:maura_bastion_system/features/bastions_page/data/bastion_inventory_store.dart';

part 'bastion_inventory_state.dart';

class BastionInventoryCubit extends Cubit<BastionInventoryState> {
  BastionInventoryCubit({BastionInventoryStore? store})
      : _store = store ?? BastionInventoryStore(),
        super(const BastionInventoryState());

  final BastionInventoryStore _store;

  void load(Bastion bastion) {
    emit(BastionInventoryState(bastionId: bastion.id));
    unawaited(_restore(bastion.id));
  }

  void addRewards(List<RewardGrant> grants) {
    var inventory = state.inventory.addGrants(grants);
    var gold = state.goldEarned;
    var sold = const <RewardGrant>[];
    if (inventory.totalWeight() > bastionStorageMaxWeight) {
      final result =
          inventory.sellDownTo(maxWeight: bastionStorageMaxWeight);
      inventory = result.inventory;
      gold += result.goldGained;
      sold = result.sold;
    }
    emit(BastionInventoryState(
      bastionId: state.bastionId,
      inventory: inventory,
      goldEarned: gold,
      lastSold: sold,
    ));
    if (state.bastionId != null) {
      unawaited(_store.save(state.bastionId!, inventory));
    }
  }

  Future<void> _restore(String bastionId) async {
    final stored = await _store.read(bastionId);
    if (stored.isEmpty || bastionId != state.bastionId) return;
    emit(BastionInventoryState(
      bastionId: state.bastionId,
      inventory: BastionInventory().addGrants(stored),
      goldEarned: state.goldEarned,
    ));
  }
}
