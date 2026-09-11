import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

class DiscordAnnouncer {
  final DiscordApi _discordApi;

  DiscordAnnouncer({required DiscordApi discordApi}) : _discordApi = discordApi;

  Future<void> announceBastionCreated(Bastion bastion) =>
      _announce(bastionCreatedMessage(bastion), _discordApi.sendBastionCreated);

  Future<void> announceFacilityBuilt(Bastion bastion, Facility facility) =>
      _announce(facilityBuiltMessage(bastion, facility), _discordApi.sendFacilityBuilt);

  Future<void> announceFacilityRankUp(
    Bastion bastion,
    Facility oldFacility,
    Facility upgraded,
  ) =>
      _announce(
        facilityRankUpMessage(bastion, oldFacility, upgraded),
        _discordApi.sendFacilityRankUp,
      );

  Future<void> announceBranchUpgradePurchased(
    Bastion bastion,
    Facility facility,
    BranchUpgrade upgrade,
  ) =>
      _announce(
        branchUpgradePurchasedMessage(bastion, facility, upgrade),
        _discordApi.sendBranchUpgradePurchased,
      );

  Future<void> announceHirelingHired(Hireling hireling, {String? bastionName}) =>
      _announce(
        hirelingHiredMessage(hireling, bastionName: bastionName),
        _discordApi.sendHirelingHired,
      );

  Future<void> announceDefenderAcquired(Defender defender, {String? bastionName}) =>
      _announce(
        defenderAcquiredMessage(defender, bastionName: bastionName),
        _discordApi.sendDefenderAcquired,
      );

  Future<void> _announce(
    String message,
    Future<void> Function(String) transport,
  ) =>
      transport(message);
}

String bastionCreatedMessage(Bastion bastion) {
  final lines = <String>['🏰 **${bastion.name}** has been founded!'];
  final description = _optionalLine(bastion.description);
  if (description != null) lines.addAll(['', description]);
  if (bastion.facilities.isNotEmpty) {
    lines.add('');
    lines.add('**Starting facilities** (${bastion.facilities.length}):');
    for (final facility in bastion.facilities) {
      lines.add(
        '• **${facility.name}** (Rank ${facility.rank.title}) — '
        '${facility.cost}gp, ${_turns(facility.constructionTurns)} to build',
      );
    }
  }
  final imgUrl = _optionalLine(bastion.imgUrl);
  if (imgUrl != null) lines.addAll(['', imgUrl]);
  return lines.join('\n');
}

String facilityBuiltMessage(Bastion bastion, Facility facility) {
  final lines = <String>[
    '🏗️ **${bastion.name}** has started construction on **${facility.name}** (Rank ${facility.rank.title})!',
  ];
  final description = _optionalLine(facility.description);
  if (description != null) lines.addAll(['', description]);
  lines.addAll([
    '',
    'Cost: ${facility.cost}gp • Build time: ${_turns(facility.constructionTurns)}'
        ' • Required hirelings: ${facility.minimumRequiredHirelings}',
  ]);
  final imgUrl = _optionalLine(facility.imgUrl);
  if (imgUrl != null) lines.add(imgUrl);
  return lines.join('\n');
}

String facilityRankUpMessage(Bastion bastion, Facility oldFacility, Facility upgraded) {
  final lines = <String>[
    '⬆️ **${bastion.name}**\'s **${upgraded.name}** is advancing from'
        ' Rank ${oldFacility.rank.title} to Rank ${upgraded.rank.title}!',
  ];
  final description = _optionalLine(upgraded.description);
  if (description != null) lines.addAll(['', description]);
  lines.addAll([
    '',
    'Upgrade cost: ${facilityUpgradeCost(oldFacility.rank)}gp'
        ' • Construction: ${_turns(upgraded.constructionTurns)}',
  ]);
  return lines.join('\n');
}

String branchUpgradePurchasedMessage(
  Bastion bastion,
  Facility facility,
  BranchUpgrade upgrade,
) {
  final lines = <String>[
    '🌟 **${bastion.name}**\'s **${facility.name}** activates **${upgrade.name}**!',
  ];
  final description = _optionalLine(upgrade.description);
  if (description != null) lines.addAll(['', description]);
  final kind = switch (upgrade.kind) {
    BranchUpgradeKind.oneTime => 'One-time purchase',
    BranchUpgradeKind.perTurn => 'Per-turn cost',
    BranchUpgradeKind.perUse => 'Per-use payment',
  };
  var details = '$kind • Cost: ${upgrade.costFor(facility.rank)}gp';
  if (upgrade.hirelingCapacity != null) details += ' • Hireling capacity: ${upgrade.hirelingCapacity}';
  lines.addAll(['', details]);
  return lines.join('\n');
}

String hirelingHiredMessage(Hireling hireling, {String? bastionName}) {
  final whoName = _optionalLine(bastionName);
  final who = whoName == null ? 'A new bastion' : '**$whoName**';
  final role = _optionalLine(hireling.role);
  final lines = <String>[
    role == null
        ? '🧑‍🌾 $who hires **${hireling.name}**!'
        : '🧑‍🌾 $who hires **${hireling.name}** as $role!',
  ];
  final description = _optionalLine(hireling.description);
  if (description != null) lines.addAll(['', description]);
  final story = _optionalLine(hireling.acquisitionStory);
  if (story != null) lines.addAll(['', 'How they were found: $story']);
  final imgUrl = _optionalLine(hireling.imgUrl);
  if (imgUrl != null) lines.addAll(['', imgUrl]);
  return lines.join('\n');
}

String defenderAcquiredMessage(Defender defender, {String? bastionName}) {
  final whoName = _optionalLine(bastionName);
  final who = whoName == null ? 'A new bastion' : '**$whoName**';
  final name = _optionalLine(defender.name) ?? 'Unnamed Defender';
  final lines = <String>[
    '🛡️ $who gains a new defender: **$name** (${defender.type.title})!',
  ];
  final description = _optionalLine(defender.description);
  if (description != null) lines.addAll(['', description]);
  final story = _optionalLine(defender.acquisitionStory);
  if (story != null) lines.addAll(['', 'How they were gained: $story']);
  final imgUrl = _optionalLine(defender.imgUrl);
  if (imgUrl != null) lines.addAll(['', imgUrl]);
  return lines.join('\n');
}

String? _optionalLine(String? text) {
  final trimmed = text?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String _turns(int turns) => turns == 1 ? '1 turn' : '$turns turns';
