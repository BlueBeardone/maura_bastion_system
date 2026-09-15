import 'package:maura_bastion_system/data/models/bastion/bastion.dart';

class BastionPage {
  final List<Bastion> bastions;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const BastionPage({
    required this.bastions,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory BastionPage.fromJson(Map<String, dynamic> json) {
    return BastionPage(
      bastions: (json['bastions'] as List? ?? [])
          .map((b) => Bastion.fromJson(b as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
