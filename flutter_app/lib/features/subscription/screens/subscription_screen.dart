import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  UserSubscription? _currentSubscription;
  List<SubscriptionTier> _tiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subscription = await SupabaseService.instance.getCurrentSubscription();
      final tiers = await SupabaseService.instance.getSubscriptionTiers();
      setState(() {
        _currentSubscription = subscription;
        _tiers = tiers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('subscription')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_currentSubscription != null) ...[
                  _buildCurrentSubscriptionCard(),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Available Plans',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ..._tiers.map((tier) => _TierCard(
                      tier: tier,
                      isCurrentTier: _currentSubscription?.tierId == tier.id,
                      onSubscribe: () => _handleSubscribe(tier),
                    )),
              ],
            ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final subscription = _currentSubscription!;
    final tier = subscription.tier;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  context.tr('current_plan'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tier != null) ...[
              Text(
                context.isArabic ? tier.displayNameAr : tier.displayNameEn,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${tier.messageLimit} ${context.tr('messages')} ${context.tr('per_hour')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(SubscriptionTier tier) async {
    // This would integrate with Stripe/HyperPay
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscribing to ${tier.displayNameEn}...'),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCurrentTier;
  final VoidCallback onSubscribe;

  const _TierCard({
    required this.tier,
    required this.isCurrentTier,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? tier.displayNameAr : tier.displayNameEn,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (isCurrentTier)
                  Chip(
                    label: Text(context.tr('current_plan')),
                    backgroundColor: Theme.of(context).primaryColor,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (tier.descriptionEn != null)
              Text(
                isArabic ? tier.descriptionAr! : tier.descriptionEn!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tier.isFree
                      ? context.tr('free_plan')
                      : '\$${tier.priceMonthly.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                if (!tier.isFree) ...[
                  const SizedBox(width: 4),
                  Text(
                    '/${context.tr('month')}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${tier.messageLimit} ${context.tr('messages')} ${tier.timeWindowHours == 1 ? context.tr('per_hour') : context.tr('per_2_hours')}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...tier.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 20, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            if (!isCurrentTier)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubscribe,
                  child: Text(tier.isFree
                      ? context.tr('current_plan')
                      : context.tr('subscribe')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
