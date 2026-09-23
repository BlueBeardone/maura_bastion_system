import 'package:maura_bastion_system/data/models/bastion/facility.dart';

/// Presentation-only view of a facility granting a benefit this turn, with
/// the result of its table roll when one was made.
class BastionTurnFacilityBuff {
  final Facility facility;
  final int hirelingCount;
  final int? rolledNumber;
  final String? rolledRow;

  const BastionTurnFacilityBuff({
    required this.facility,
    this.hirelingCount = 0,
    this.rolledNumber,
    this.rolledRow,
  });
}