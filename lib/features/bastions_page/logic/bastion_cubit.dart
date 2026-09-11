import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  final BastionApi _bastionApi;
  final FacilityApi _facilityApi;
  final DiscordAnnouncer? _discordAnnouncer;
  bool _advancingTurn = false;
  bool _upgrading = false;

  BastionCubit({
    required BastionApi bastionApi,
    required FacilityApi facilityApi,
    DiscordAnnouncer? discordAnnouncer,
  })  : _bastionApi = bastionApi,
        _facilityApi = facilityApi,
        _discordAnnouncer = discordAnnouncer,
        super(BastionLoadingState());

  Future<void> loadBastions() async {
    try {
      final bastions = await _bastionApi.getAll();
      emit(BastionLoadedState(bastions: bastions));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to load bastions'));
    }
  }

  Future<void> addFacility(String bastionId, Facility facility) async {
    try {
      if (state is BastionLoadedState) {
        final bastions = (state as BastionLoadedState).bastions;
        final bastion = bastions.isEmpty
            ? null
            : bastions.firstWhere(
                (b) => b.id == bastionId,
                orElse: () => bastions.first,
              );
        if (bastion != null) {
          try {
            await _discordAnnouncer?.announceFacilityBuilt(bastion, facility);
          } catch (e, stackTrace) {
            emit(BastionErrorState(
              error: e as Exception,
              stackTrace: stackTrace,
              message: 'Discord log failed — facility not built',
            ));
            return;
          }
        }
      }
      await _facilityApi.create(facility, bastionId);
      await loadBastions();
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to add facility'));
    }
  }

  Future<Facility?> advanceBastionTurn(
    String bastionId, {
    Future<void> Function(Facility? advanced)? gate,
  }) async {
    if (_advancingTurn) return null;
    if (state is! BastionLoadedState) return null;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    Facility? target;
    for (final facility in bastion.facilities) {
      if (facility.constructedTurns < facility.constructionTurns) {
        target = facility;
        break;
      }
    }

    try {
      _advancingTurn = true;
      if (target == null) {
        if (gate != null) {
          try {
            await gate(null);
          } catch (e, stackTrace) {
            emit(BastionErrorState(
              error: e as Exception,
              stackTrace: stackTrace,
              message: 'Discord log failed — turn not advanced',
            ));
            return null;
          }
        }
        return null;
      }

      var advanced = target.copyWith(
        constructedTurns: target.constructedTurns + 1,
      );

      // Lapse per-turn branch upgrades (e.g. Pub of Legend) at turn advance.
      final targetPerTurnActive = target.branchUpgrade?.kind ==
              BranchUpgradeKind.perTurn &&
          target.branchUpgradeActive;
      if (targetPerTurnActive) {
        advanced = advanced.copyWith(branchUpgradeActive: false);
      }
      final lapsed = <Facility>[];
      for (final facility in bastion.facilities) {
        if (facility.id == target.id) continue;
        final isPerTurn = facility.branchUpgrade?.kind == BranchUpgradeKind.perTurn;
        if (isPerTurn && facility.branchUpgradeActive) {
          lapsed.add(facility.copyWith(branchUpgradeActive: false));
        }
      }

      if (gate != null) {
        try {
          await gate(advanced);
        } catch (e, stackTrace) {
          emit(BastionErrorState(
            error: e as Exception,
            stackTrace: stackTrace,
            message: 'Discord log failed — turn not advanced',
          ));
          return null;
        }
      }
      await _facilityApi.update(advanced.id, advanced, bastionId: bastion.id);
      for (final facility in lapsed) {
        await _facilityApi.update(facility.id, facility, bastionId: bastion.id);
      }
      await loadBastions();
      return advanced;
    } catch (e, stackTrace) {
      emit(BastionErrorState(
        error: e as Exception,
        stackTrace: stackTrace,
        message: 'Failed to advance bastion turn',
      ));
      return null;
    } finally {
      _advancingTurn = false;
    }
  }

  Future<Facility?> upgradeFacility(String bastionId, Facility facility) async {
    if (_upgrading) return null;
    if (state is! BastionLoadedState) return null;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    if (facility.rank == Rank.S) return null;
    if (!upgradeableFacilityIds.contains(facility.id)) return null;
    final nextRank = facility.rank.next;
    if (nextRank == null) return null;
    final anyBusy = bastion.facilities
        .any((f) => f.constructedTurns < f.constructionTurns);
    if (anyBusy) return null;

    final oldFacility = facility;
    final upgraded = facility.copyWith(
      rank: nextRank,
      constructionTurns: 2,
      cost: baseCostByRank[nextRank]!,
      constructedTurns: 0,
    );

    try {
      _upgrading = true;
      try {
        await _discordAnnouncer
            ?.announceFacilityRankUp(bastion, oldFacility, upgraded);
      } catch (e, stackTrace) {
        emit(BastionErrorState(
          error: e as Exception,
          stackTrace: stackTrace,
          message: 'Discord log failed — facility not upgraded',
        ));
        return null;
      }
      await _facilityApi.update(upgraded.id, upgraded, bastionId: bastion.id);
      await loadBastions();
      return upgraded;
    } catch (e, stackTrace) {
      emit(BastionErrorState(
        error: e as Exception,
        stackTrace: stackTrace,
        message: 'Failed to upgrade facility',
      ));
      return null;
    } finally {
      _upgrading = false;
    }
  }

  Future<Facility?> purchaseBranchUpgrade(
      String bastionId, Facility facility) async {
    if (_upgrading) return null;
    if (state is! BastionLoadedState) return null;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    final upgrade = branchUpgradeFor(facility.id);
    if (upgrade == null) return null;
    // perUse upgrades (Theatre Stage Enhancements) are per-play payments with
    // no persistent state — never recorded here.
    if (upgrade.kind == BranchUpgradeKind.perUse) return null;
    if (facility.hasActiveBranchUpgrade) return null;
    if (facility.constructedTurns < facility.constructionTurns) return null;
    final anyBusy = bastion.facilities
        .any((f) => f.constructedTurns < f.constructionTurns);
    if (anyBusy) return null;

    final purchased = facility.copyWith(
      branchUpgradeId: upgrade.id,
      branchUpgradeActive: true,
    );

    try {
      _upgrading = true;
      try {
        await _discordAnnouncer
            ?.announceBranchUpgradePurchased(bastion, purchased, upgrade);
      } catch (e, stackTrace) {
        emit(BastionErrorState(
          error: e as Exception,
          stackTrace: stackTrace,
          message: 'Discord log failed — upgrade not purchased',
        ));
        return null;
      }
      await _facilityApi.update(purchased.id, purchased, bastionId: bastion.id);
      await loadBastions();
      return purchased;
    } catch (e, stackTrace) {
      emit(BastionErrorState(
        error: e as Exception,
        stackTrace: stackTrace,
        message: 'Failed to purchase branch upgrade',
      ));
      return null;
    } finally {
      _upgrading = false;
    }
  }

  Future<Bastion?> createBastion(
    String name,
    String description,
    String? imgUrl,
    List<Facility> facilities,
  ) async {
    final builtFacilities = facilities.map((f) => Facility(
      id: f.id,
      name: f.name,
      rank: f.rank,
      description: f.description,
      imgUrl: f.imgUrl,
      table: f.table,
      minimumRequiredHirelings: f.minimumRequiredHirelings,
      constructionTurns: f.constructionTurns,
      cost: f.cost,
      constructedTurns: 0,
    )).toList();
    final localBastion = Bastion(
      id: '',
      name: name,
      description: description,
      imgUrl: imgUrl,
      facilities: builtFacilities,
    );

    try {
      try {
        await _discordAnnouncer?.announceBastionCreated(localBastion);
      } catch (e, stackTrace) {
        emit(BastionErrorState(
          error: e as Exception,
          stackTrace: stackTrace,
          message: 'Discord log failed — bastion not created',
        ));
        return null;
      }
      final newBastion = await _bastionApi.create(localBastion);

      final bastions = state is BastionLoadedState
          ? List<Bastion>.from((state as BastionLoadedState).bastions)
          : <Bastion>[];
      bastions.add(newBastion);
      emit(BastionLoadedState(bastions: bastions));
      return newBastion;
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to create bastion'));
      return null;
    }
  }
}