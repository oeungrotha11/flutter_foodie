import 'package:flutter/material.dart';

import '../models/customer_reward.dart';
import '../services/foodie_api.dart';
import '../widgets/foodie_sliver_app_bar.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<List<CustomerReward>> _rewardsFuture;

  @override
  void initState() {
    super.initState();
    _rewardsFuture = FoodieApi.instance.rewards();
  }

  Future<void> _refresh() async {
    final future = FoodieApi.instance.rewards();
    setState(() => _rewardsFuture = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: const FoodieAppBar(
      title: 'Reward wallet',
      showBackButton: true,
      showSearchButton: false,
      showCartButton: false,
    ),
    body: FutureBuilder<List<CustomerReward>>(
      future: _rewardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF5233B)));
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return _message(
            icon: Icons.wallet_outlined,
            title: 'Wallet unavailable',
            detail: snapshot.error.toString(),
            action: TextButton(onPressed: _refresh, child: const Text('Try again')),
          );
        }
        final rewards = snapshot.data ?? const <CustomerReward>[];
        final available = rewards.where((reward) => reward.isAvailable).toList();
        final history = rewards.where((reward) => !reward.isAvailable).toList();
        if (rewards.isEmpty) {
          return _message(
            icon: Icons.card_giftcard_outlined,
            title: 'No rewards yet',
            detail: 'Rewards you earn from completed orders will show up here.',
            action: TextButton(onPressed: _refresh, child: const Text('Refresh wallet')),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _walletHeader(available.length),
              if (available.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Ready to use'),
                const SizedBox(height: 10),
                ...available.map((reward) => _rewardCard(reward)),
              ],
              if (history.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Reward history'),
                const SizedBox(height: 10),
                ...history.map((reward) => _rewardCard(reward)),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _walletHeader(int availableCount) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF5233B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 34),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your rewards', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$availableCount available', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );

  Widget _rewardCard(CustomerReward reward) {
    final percent = (reward.discountRate * 100).round();
    final available = reward.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9ED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: available ? const Color(0xFFFFEEF0) : const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.local_offer_outlined, color: available ? const Color(0xFFF5233B) : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$percent% off your food subtotal', style: const TextStyle(color: Color(0xFF686A73), fontSize: 12)),
                Text('Minimum order: \$${reward.minimumRedemptionSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF686A73), fontSize: 12)),
                if (reward.expiresAt != null)
                  Text('${available ? 'Expires' : 'Valid until'} ${_formatDate(reward.expiresAt!)}', style: const TextStyle(color: Color(0xFF858791), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusChip(reward.displayStatus),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final available = status == 'AVAILABLE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE7F5EB) : const Color(0xFFF1F1F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: available ? const Color(0xFF217A45) : const Color(0xFF696B73))),
    );
  }

  Widget _message({required IconData icon, required String title, required String detail, required Widget action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xFFF5233B)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF777982))),
          action,
        ],
      ),
    ),
  );

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
