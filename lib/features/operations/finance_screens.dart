import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'operation_store.dart';

class PilotWalletScreen extends StatelessWidget {
  const PilotWalletScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OperationStore.instance,
    builder: (_, _) {
      final balance = OperationStore.instance.pilotAvailableBalance;
      return _FinanceScaffold(
        title: 'Wallet & Earnings',
        balanceLabel: 'Available balance',
        balance: balance,
        items: OperationStore.instance.missions
            .where((mission) => mission.stage == MissionStage.completed)
            .map(
              (mission) => _FinanceItem(
                title: mission.application.job.title,
                detail: 'Funds released',
                amount: mission.amount,
                positive: true,
              ),
            )
            .toList(),
        empty: 'Completed missions will appear in your earnings.',
      );
    },
  );
}

class CompanyPaymentsScreen extends StatelessWidget {
  const CompanyPaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OperationStore.instance,
    builder: (_, _) {
      final held = OperationStore.instance.companyEscrowBalance;
      return _FinanceScaffold(
        title: 'Payments & Invoices',
        balanceLabel: 'Funds held in escrow',
        balance: held,
        items: OperationStore.instance.missions
            .where(
              (mission) =>
                  mission.stage != MissionStage.offerSent &&
                  mission.stage != MissionStage.rejected,
            )
            .map(
              (mission) => _FinanceItem(
                title: mission.application.job.title,
                detail: mission.stage == MissionStage.completed
                    ? 'Paid to pilot'
                    : 'Secured for mission',
                amount: mission.amount,
                positive: false,
              ),
            )
            .toList(),
        empty: 'Funded missions and invoices will appear here.',
      );
    },
  );
}

class _FinanceScaffold extends StatelessWidget {
  const _FinanceScaffold({
    required this.title,
    required this.balanceLabel,
    required this.balance,
    required this.items,
    required this.empty,
  });
  final String title;
  final String balanceLabel;
  final double balance;
  final List<_FinanceItem> items;
  final String empty;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balanceLabel,
                  style: const TextStyle(
                    color: Color(0xFFC8D5EC),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All financial actions are recorded in your transaction history.',
                  style: TextStyle(color: Color(0xFFC8D5EC), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Transaction history',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty) _Empty(message: empty) else ...items,
        ],
      ),
    ),
  );
}

class _FinanceItem extends StatelessWidget {
  const _FinanceItem({
    required this.title,
    required this.detail,
    required this.amount,
    required this.positive,
  });
  final String title;
  final String detail;
  final double amount;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: positive ? AppColors.greenBg : AppColors.blueBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            positive ? Icons.south_west_rounded : Icons.lock_outline_rounded,
            color: positive ? AppColors.green : AppColors.blue,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
              ),
            ],
          ),
        ),
        Text(
          '${positive ? '+' : ''}\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: positive ? AppColors.green : AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.lightGrey,
          size: 34,
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey, fontSize: 13),
        ),
      ],
    ),
  );
}
