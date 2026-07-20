class AiUsageQuota {
  final int used;
  final int limit;

  const AiUsageQuota({required this.used, required this.limit});

  factory AiUsageQuota.fromJson(Map<String, dynamic> json) {
    return AiUsageQuota(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isExhausted => used >= limit;
}

class AiUsageStatus {
  final bool isPremium;
  final AiUsageQuota chat;
  final AiUsageQuota generate;
  final AiUsageQuota analyze;
  final bool budgetExhausted;

  const AiUsageStatus({
    required this.isPremium,
    required this.chat,
    required this.generate,
    required this.analyze,
    required this.budgetExhausted,
  });

  factory AiUsageStatus.fromJson(Map<String, dynamic> json) {
    return AiUsageStatus(
      isPremium: json['isPremium'] == true,
      chat: AiUsageQuota.fromJson(
        Map<String, dynamic>.from(json['chat'] ?? {}),
      ),
      generate: AiUsageQuota.fromJson(
        Map<String, dynamic>.from(json['generate'] ?? {}),
      ),
      analyze: AiUsageQuota.fromJson(
        Map<String, dynamic>.from(json['analyze'] ?? {}),
      ),
      budgetExhausted: json['budgetExhausted'] == true,
    );
  }
}
