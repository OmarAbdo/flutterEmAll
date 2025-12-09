import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

@JsonSerializable()
class SubscriptionTier {
  final String id;
  final String name;
  final String displayNameEn;
  final String displayNameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final double priceMonthly;
  final double priceYearly;
  final int messageLimit;
  final int timeWindowHours;
  final List<String> features;
  final bool isActive;

  SubscriptionTier({
    required this.id,
    required this.name,
    required this.displayNameEn,
    required this.displayNameAr,
    this.descriptionEn,
    this.descriptionAr,
    required this.priceMonthly,
    required this.priceYearly,
    required this.messageLimit,
    required this.timeWindowHours,
    required this.features,
    this.isActive = true,
  });

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTierFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionTierToJson(this);

  bool get isFree => name == 'free';
  bool get isPremium => name == 'premium_1' || name == 'premium_2';
}

@JsonSerializable()
class UserSubscription {
  final String id;
  final String userId;
  final String tierId;
  final String status;
  final String? paymentProvider;
  final String? externalSubscriptionId;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final SubscriptionTier? tier;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.tierId,
    required this.status,
    this.paymentProvider,
    this.externalSubscriptionId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.tier,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$UserSubscriptionToJson(this);

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled';
  bool get isExpired => status == 'expired';
}

@JsonSerializable()
class UsageInfo {
  final int currentUsage;
  final int limit;
  final int remaining;
  final int timeWindowHours;
  final String tierName;
  final DateTime? resetAt;
  final bool allowed;

  UsageInfo({
    required this.currentUsage,
    required this.limit,
    required this.remaining,
    required this.timeWindowHours,
    required this.tierName,
    this.resetAt,
    required this.allowed,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) =>
      _$UsageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UsageInfoToJson(this);

  double get usagePercentage => currentUsage / limit;
}
