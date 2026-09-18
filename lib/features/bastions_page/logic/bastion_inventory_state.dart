part of 'bastion_inventory_cubit.dart';

class BastionInventoryState extends Equatable {
  final String? bastionId;
  final BastionInventory inventory;
  final int goldEarned;
  final List<RewardGrant> lastSold;

  const BastionInventoryState({
    this.bastionId,
    this.inventory = const BastionInventory(),
    this.goldEarned = 0,
    this.lastSold = const [],
  });

  @override
  List<Object?> get props => [bastionId, inventory, goldEarned, lastSold];
}
