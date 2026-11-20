class Subscription {
  final int id;
  final String plan;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  Subscription({
    required this.id,
    required this.plan,
    required this.status,
    this.startsAt,
    this.endsAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      plan: json['plan'] ?? '',
      status: json['status'] ?? '',
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at']) : null,
    );
  }

  bool get isActive => status == 'active' && (endsAt == null || endsAt!.isAfter(DateTime.now()));
}

class PlanTier {
  final int durationMonths;
  final String label;
  final double priceDh;

  PlanTier({
    required this.durationMonths,
    required this.label,
    required this.priceDh,
  });

  factory PlanTier.fromJson(Map<String, dynamic> json) {
    return PlanTier(
      durationMonths: (json['duration_months'] ?? 1).toInt(),
      label: json['label'] ?? '',
      priceDh: (json['price_dh'] ?? 0).toDouble(),
    );
  }
}

class Plan {
  final String key;
  final String name;
  final int livesPerMonth;
  final String description;
  final List<String> features;
  final List<PlanTier> tiers;

  Plan({
    required this.key,
    required this.name,
    required this.livesPerMonth,
    required this.description,
    required this.features,
    required this.tiers,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      livesPerMonth: (json['lives_per_month'] ?? 0).toInt(),
      description: json['description'] ?? '',
      features: (json['features'] as List? ?? []).map((e) => e.toString()).toList(),
      tiers: (json['tiers'] as List? ?? [])
          .map((e) => PlanTier.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
