import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_page.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';

part 'bastion_state.dart';

class BastionCubit extends Cubit<BastionState> {
  final BastionApi _bastionApi;
  final FacilityApi _facilityApi;
  final HirelingApi? _hirelingApi;
  final DiscordAnnouncer? _discordAnnouncer;
  bool _advancingTurn = false;
  bool _upgrading = false;

  BastionCubit({
    required BastionApi bastionApi,
    required FacilityApi facilityApi,
    HirelingApi? hirelingApi,
    DiscordAnnouncer? discordAnnouncer,
  })  : _bastionApi = bastionApi,
        _facilityApi = facilityApi,
        _hirelingApi = hirelingApi,
        _discordAnnouncer = discordAnnouncer,
        super(BastionLoadingState());

  Future<void> loadBastions() async {
    try {
      final results = await Future.wait([
        _bastionApi.getMine(),
        _bastionApi.browse(page: 1),
      ]);
      final mine = results[0] as List<Bastion>;
      final page = results[1] as BastionPage;
      emit(BastionLoadedState(
        userBastion: mine.isEmpty ? null : mine.first,
        browseBastions: page.bastions,
        currentPage: page.page,
        hasMore: page.hasMore,
      ));
    } catch (e, stackTrace) {
      emit(BastionErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Failed to load bastions'));
    }
  }

  /// Re-fetches only the caller's own bastion — used after mutations so the
  /// browse pages and scroll position are preserved.
  Future<void> refreshUserBastion() async {
    if (state is! BastionLoadedState) return;
    try {
      final mine = await _bastionApi.getMine();
      final loaded = state as BastionLoadedState;
      emit(loaded.copyWith(
        userBastion: mine.isEmpty ? null : mine.first,
        clearUserBastion: mine.isEmpty,
      ));
    } catch (_) {
      // Keep the current state; the pinned card stays as-is.
    }
  }

  Future<void> loadMore() async {
    if (state is! BastionLoadedState) return;
    final loaded = state as BastionLoadedState;
    if (!loaded.hasMore || loaded.isLoadingMore) return;
    final nextPage = loaded.currentPage + 1;
    emit(loaded.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await _bastionApi.browse(page: nextPage);
      if (state is! BastionLoadedState) return;
      final current = state as BastionLoadedState;
      if (current.currentPage >= nextPage) return; // reset happened mid-flight
      emit(current.copyWith(
        browseBastions: [...current.browseBastions, ...page.bastions],
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
        loadMoreFailed: false,
      ));
    } catch (_) {
      if (state is BastionLoadedState) {
        emit((state as BastionLoadedState).copyWith(isLoadingMore: false, loadMoreFailed: true));
      }
    }
  }

  void _setMutating(bool mutating) {
    if (state is BastionLoadedState) {
      emit((state as BastionLoadedState).copyWith(isMutating: mutating));
    }
  }

  Future<bool> addFacility(String bastionId, Facility facility) async {
    if (state is! BastionLoadedState) return false;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.isEmpty
        ? null
        : loaded.bastions.firstWhere(
            (b) => b.id == bastionId,
            orElse: () => loaded.bastions.first,
          );
    if (bastion == null) return false;
    if (bastion.facilities.length >= maxFacilitiesPerBastion) return false;
    if (isSRankBaseFacility(facility) &&
        bastion.facilities.any(isSRankBaseFacility)) {
      return false;
    }

    try {
      await _discordAnnouncer?.announceFacilityBuilt(bastion, facility);
      _setMutating(true);
      await _facilityApi.create(facility, bastionId);
      await refreshUserBastion();
      return true;
    } catch (e) {
      _setMutating(false);
      return false;
    }
  }

  Future<bool> removeFacility(String bastionId, Facility facility) async {
    if (state is! BastionLoadedState) return false;

    final loaded = state as BastionLoadedState;
    final bastion = loaded.bastions.firstWhere(
      (b) => b.id == bastionId,
      orElse: () => loaded.bastions.first,
    );

    try {
      _setMutating(true);
      await _discordAnnouncer?.announceFacilityRemoved(bastion, facility);
      for (final hireling in bastion.getFacilityHirelings(facility.id)) {
        await _hirelingApi?.update(
          hireling.id,
          hireling.copyWith(facilityId: null),
        );
      }
      await _facilityApi.delete(facility.id);
      await refreshUserBastion();
      return true;
    } catch (e) {
      _setMutating(false);
      return false;
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
      _setMutating(true);
      if (target == null) {
        if (gate != null) {
          try {
            await gate(null);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      var advanced = target.copyWith(
        constructedTurns: target.constructedTurns + 1,
      );

      // Lapse per-turn branch upgrades (e.g. Pub of Legend) at turn advance
      // by reverting them to the base name/description.
      final targetPerTurnUpgrade =
          target.branchUpgrade?.kind == BranchUpgradeKind.perTurn;
      if (targetPerTurnUpgrade) {
        advanced = advanced.revertBranchUpgrade();
      }
      final lapsed = <Facility>[];
      for (final facility in bastion.facilities) {
        if (facility.id == target.id) continue;
        final isPerTurn = facility.branchUpgrade?.kind == BranchUpgradeKind.perTurn;
        if (isPerTurn) {
          lapsed.add(facility.revertBranchUpgrade());
        }
      }

      if (gate != null) {
        try {
          await gate(advanced);
        } catch (e) {
          return null;
        }
      }
      await _facilityApi.update(advanced.id, advanced, bastionId: bastion.id);
      for (final facility in lapsed) {
        await _facilityApi.update(facility.id, facility, bastionId: bastion.id);
      }
      await refreshUserBastion();
      return advanced;
    } catch (e) {
      return null;
    } finally {
      _advancingTurn = false;
      _setMutating(false);
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
      _setMutating(true);
      try {
        await _discordAnnouncer
            ?.announceFacilityRankUp(bastion, oldFacility, upgraded);
      } catch (e) {
        return null;
      }
      await _facilityApi.update(upgraded.id, upgraded, bastionId: bastion.id);
      await refreshUserBastion();
      return upgraded;
    } catch (e) {
      return null;
    } finally {
      _upgrading = false;
      _setMutating(false);
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

    final upgrade = branchUpgradeForFacility(facility);
    if (upgrade == null) return null;
    // perUse upgrades (Theatre Stage Enhancements) are per-play payments with
    // no persistent state — never recorded here.
    if (upgrade.kind == BranchUpgradeKind.perUse) return null;
    if (facility.hasActiveBranchUpgrade) return null;
    if (facility.constructedTurns < facility.constructionTurns) return null;
    final anyBusy = bastion.facilities
        .any((f) => f.constructedTurns < f.constructionTurns);
    if (anyBusy) return null;

    final purchased = facility.applyBranchUpgrade(upgrade);

    try {
      _upgrading = true;
      _setMutating(true);
      try {
        await _discordAnnouncer
            ?.announceBranchUpgradePurchased(bastion, facility, upgrade);
      } catch (e) {
        return null;
      }
      await _facilityApi.update(purchased.id, purchased, bastionId: bastion.id);
      await refreshUserBastion();
      return purchased;
    } catch (e) {
      return null;
    } finally {
      _upgrading = false;
      _setMutating(false);
    }
  }

  Future<Bastion?> createBastion(
    String name,
    String description,
    String? imgUrl,
    List<Facility> facilities,
  ) async {
    if (facilities.length > maxFacilitiesPerBastion) return null;
    if (facilities.where(isSRankBaseFacility).length > 1) return null;

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
      } catch (e) {
        return null;
      }
      final newBastion = await _bastionApi.create(localBastion);

      final current = state is BastionLoadedState
          ? state as BastionLoadedState
          : const BastionLoadedState();
      emit(current.copyWith(userBastion: newBastion));
      return newBastion;
    } catch (e) {
      return null;
    }
  }
}
