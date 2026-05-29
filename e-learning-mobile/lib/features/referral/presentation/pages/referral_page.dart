import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/referral_repository.dart';

class ReferralPage extends ConsumerWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(referralRepositoryProvider);

    return AppScaffold(
      title: 'Referral',
      child: FutureBuilder(
        future: repository.getMyReferral(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load referral: ${snapshot.error}'),
            );
          }

          final referral = snapshot.data;
          if (referral == null) {
            return const Center(child: Text('No referral data found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Referral code'),
                  subtitle: Text(referral.referralCode),
                ),
                ListTile(
                  title: const Text('Discount code'),
                  subtitle: Text(referral.discountCode ?? 'N/A'),
                ),
                ListTile(
                  title: const Text('Discount %'),
                  subtitle: Text('${referral.discountPercent ?? 0}'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
