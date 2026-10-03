import 'package:flutter/material.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/shared/models/phase3_account_summary.dart';

class Phase3OverviewCard extends StatelessWidget {
  const Phase3OverviewCard({
    super.key,
    required this.audience,
    required this.summary,
    required this.loading,
    required this.hasSnapshot,
    required this.errorMessage,
    required this.onRetry,
    required this.onContractsTap,
    required this.onPaymentsTap,
    required this.onSubscriptionTap,
  });

  final Phase3OverviewAudience audience;
  final Phase3AccountSummary summary;
  final bool loading;
  final bool hasSnapshot;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onContractsTap;
  final VoidCallback onPaymentsTap;
  final VoidCallback onSubscriptionTap;

  bool get _company => audience == Phase3OverviewAudience.company;

  @override
  Widget build(BuildContext context) {
    if (loading && !hasSnapshot) {
      return const _OverviewSkeleton();
    }

    if (!hasSnapshot && errorMessage != null) {
      return _OverviewError(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    final metrics = <_MetricData>[
      _MetricData(
        label: 'Active',
        value: summary.activeContracts,
        icon: Icons.bolt_rounded,
        accent: AppColors.green,
      ),
      _MetricData(
        label: 'In Progress',
        value: summary.inProgressContracts,
        icon: Icons.flight_takeoff_rounded,
        accent: AppColors.blue,
      ),
      _MetricData(
        label: _company ? 'To Review' : 'Submitted',
        value: _company
            ? summary.submissionsAwaitingReviewCount
            : summary.submittedContracts,
        icon: _company
            ? Icons.fact_check_outlined
            : Icons.cloud_done_outlined,
        accent: AppColors.orange,
      ),
      _MetricData(
        label: 'Completed',
        value: summary.completedContracts,
        icon: Icons.verified_rounded,
        accent: AppColors.logoTurquoiseDark,
      ),
    ];

    final subscription = summary.currentSubscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.065),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contracts & Payments',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Live Phase 3 overview',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (loading && hasSnapshot)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 76,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                ),
                itemBuilder: (_, index) => _MetricCard(data: metrics[index]),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniSummary(
                        icon: _company
                            ? Icons.hourglass_bottom_rounded
                            : Icons.pending_actions_rounded,
                        label: _company
                            ? 'Awaiting pilot'
                            : 'Needs your action',
                        value: '${summary.contractsAwaitingActionCount}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: AppColors.cardBorder,
                    ),
                    Expanded(
                      child: _MiniSummary(
                        icon: Icons.schedule_send_rounded,
                        label: 'Pending release',
                        value: _money(summary.pendingReleaseTotal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSubscriptionTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue.withOpacity(0.07),
                          AppColors.logoTurquoiseDark.withOpacity(0.055),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.logoTurquoiseDark,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscription == null
                                    ? 'No current subscription'
                                    : 'Subscription ${subscription.statusLabel}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subscription == null
                                    ? 'Open plans and activate your plan'
                                    : 'Plan #${subscription.planId} • Manage plan & billing history',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onContractsTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 17),
                      label: const Text(
                        'Contracts',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onPaymentsTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined,
                          size: 17),
                      label: const Text(
                        'Payments',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _money(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

enum Phase3OverviewAudience { pilot, company }

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: data.accent.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.accent.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.accent, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.logoTurquoiseDark, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 8.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F5),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
