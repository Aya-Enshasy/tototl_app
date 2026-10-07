import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/pilot_contract_controller.dart';
import '../../models/pilot_contract_model.dart';
import '../../services/pilot_contract_service.dart';
import 'pilot_contract_detail_screen.dart';

class PilotContractsScreen extends StatefulWidget {
  const PilotContractsScreen({super.key});

  @override
  State<PilotContractsScreen> createState() => _PilotContractsScreenState();
}

class _PilotContractsScreenState extends State<PilotContractsScreen>
    with WidgetsBindingObserver {
  late final PilotContractController _controller;

  bool _loading = true;
  bool _refreshing = false;
  bool _silentRefreshing = false;
  String? _error;
  String _filter = '';

  Timer? _liveRefreshTimer;

  static const List<_ContractFilter> _filters = [
    _ContractFilter('', 'All'),
    _ContractFilter('pending', 'Pending'),
    _ContractFilter('accepted', 'Accepted'),
    _ContractFilter('active', 'Active'),
    _ContractFilter('in_progress', 'In Progress'),
    _ContractFilter('submitted', 'Submitted'),
    _ContractFilter('completed', 'Completed'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = PilotContractController(
      PilotContractService(ApiClient()),
    );

    WidgetsBinding.instance.addObserver(this);

    unawaited(_load());

    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_silentRefresh()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_silentRefresh(force: true));
    }
  }

  Future<void> _silentRefresh({
    bool force = false,
  }) async {
    if (!mounted || _silentRefreshing || _loading || _refreshing) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!force && lifecycle != AppLifecycleState.resumed) return;

    _silentRefreshing = true;

    try {
      final success = await _controller.loadContracts(
        status: _filter.isEmpty ? null : _filter,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _error = null;
        });
      }
    } finally {
      _silentRefreshing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({
    bool refresh = false,
  }) async {
    if (refresh && _refreshing) return;

    if (mounted) {
      setState(() {
        if (refresh) {
          _refreshing = true;
        } else {
          _loading = true;
        }
        _error = null;
      });
    }

    final success = await _controller.loadContracts(
      status: _filter.isEmpty ? null : _filter,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _refreshing = false;
      _error = success ? null : _controller.listErrorMessage;
    });
  }

  Future<void> _changeFilter(String value) async {
    if (_filter == value) return;

    HapticFeedback.selectionClick();
    setState(() {
      _filter = value;
      _loading = true;
      _error = null;
    });

    await _load();
  }

  Future<void> _openContract(PilotContractModel contract) async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PilotContractDetailScreen(
          contractId: contract.id,
          initialContract: contract,
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _load(refresh: true);
    } else {
      unawaited(_silentRefresh(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractsCount = _controller.contracts.length;
    final actionCount = _controller.contracts
        .where((item) => item.isPending)
        .length;
    final activeCount = _controller.contracts
        .where((item) =>
            item.isActive ||
            item.isInProgress ||
            item.isSubmitted)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          const _PremiumContractsBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _PremiumContractsHeader(
                  total: contractsCount,
                  actionCount: actionCount,
                  activeCount: activeCount,
                  syncing: _silentRefreshing || _refreshing,
                  onBack: () => Navigator.of(context).pop(),
                  onRefresh: _refreshing
                      ? null
                      : () => _load(refresh: true),
                ),
                _premiumFiltersBar(),
                Expanded(
                  child: _loading
                      ? const _ContractsShimmer()
                      : _error != null
                          ? _ErrorState(
                              message: _error!,
                              onRetry: _load,
                            )
                          : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFiltersBar() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final item = _filters[index];
          final selected = _filter == item.value;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _changeFilter(item.value),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF09283F)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF09283F)
                        : AppColors.cardBorder,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF09283F).withOpacity(.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  AppLanguage.text(item.label),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.grey,
                    fontSize: 9.7,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _content() {
    final contracts = _controller.contracts;

    if (contracts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.blue,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 95, 22, 30),
          children: const [
            _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () => _load(refresh: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
        itemCount: contracts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (_, index) {
          final contract = contracts[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(
              milliseconds: 260 + (index.clamp(0, 8).toInt() * 45),
            ),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (_, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _ContractCard(
              contract: contract,
              onTap: () => _openContract(contract),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumContractsHeader extends StatelessWidget {
  const _PremiumContractsHeader({
    required this.total,
    required this.actionCount,
    required this.activeCount,
    required this.syncing,
    required this.onBack,
    required this.onRefresh,
  });

  final int total;
  final int actionCount;
  final int activeCount;
  final bool syncing;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06182A),
              Color(0xFF07384A),
              Color(0xFF087C88),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF087C88).withOpacity(.14),
              blurRadius: 25,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _DarkRoundButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MISSION CONTRACTS',
                        style: TextStyle(
                          color: Color(0xFF78DDD6),
                          fontSize: 7.9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLanguage.text('My Contracts'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (syncing)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.09),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF7CE2DA),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _DarkRoundButton(
                    icon: Icons.sync_rounded,
                    onTap: onRefresh ?? () {},
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _HeaderMetric(
                    label: 'Total',
                    value: total,
                    icon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderMetric(
                    label: 'Your action',
                    value: actionCount,
                    icon: Icons.notifications_active_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderMetric(
                    label: 'Live',
                    value: activeCount,
                    icon: Icons.flight_takeoff_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.075),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withOpacity(.055),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7CE2DA),
            size: 14,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.52),
                    fontSize: 7.3,
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

class _DarkRoundButton extends StatelessWidget {
  const _DarkRoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.09),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(.10),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _PremiumContractsBackdrop extends StatelessWidget {
  const _PremiumContractsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -160,
              right: -120,
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0FA6B4).withOpacity(.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -170,
              left: -120,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0AA37F).withOpacity(.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _contractNextStep(PilotContractModel contract) {
  if (contract.isPending) {
    return 'Review and accept or reject the agreement';
  }
  if (contract.isAccepted) {
    return 'Waiting for company funding';
  }
  if (contract.isActive) {
    return 'Review exact location and start the mission';
  }
  if (contract.isInProgress) {
    return 'Complete the mission and submit your work';
  }
  if (contract.isSubmitted) {
    return 'Waiting for company review';
  }
  if (contract.isCompleted) {
    return 'Mission complete';
  }
  if (contract.isRejected) {
    return 'Contract rejected';
  }
  if (contract.isCancelled) {
    return 'Contract cancelled';
  }
  if (contract.isTerminated) {
    return 'Contract terminated';
  }
  return contract.statusLabel;
}

class _ContractFilter {
  final String value;
  final String label;

  const _ContractFilter(this.value, this.label);
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.contract,
    required this.onTap,
  });

  final PilotContractModel contract;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(contract.status);
    final next = _contractNextStep(contract);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.cardBorder.withOpacity(.92),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(.032),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF08263D),
                            Color(0xFF0A7F8E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract #${contract.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13.4,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mission #${contract.jobPostingId} · Application #${contract.jobApplicationId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 8.7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: contract.statusLabel,
                      foreground: visual.foreground,
                      background: visual.background,
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: const Color(0xFFF0F3F5),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PremiumListMetric(
                            label: 'Contract Value',
                            value: contract.amountLabel,
                            icon: Icons.account_balance_wallet_outlined,
                            accent: const Color(0xFF0AA37F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PremiumListMetric(
                            label: 'Payment',
                            value: contract.paymentTypeLabel,
                            icon: Icons.tune_rounded,
                            accent: const Color(0xFF0B8FA8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFB),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            color: Color(0xFF0B8FA8),
                            size: 15,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NEXT STEP',
                                  style: TextStyle(
                                    color: AppColors.lightGrey,
                                    fontSize: 7.1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .55,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  next,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 9.4,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF078B98),
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.lightGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contract.dateRangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumListMetric extends StatelessWidget {
  const _PremiumListMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 14,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 7.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w900,
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


class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.blue,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(label),
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.blue,
            size: 31,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLanguage.text('No contracts yet'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          AppLanguage.text(
            'Contracts created by companies after accepting your applications will appear here.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11.2,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 34,
              color: AppColors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
              ),
              child: Text(AppLanguage.text('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            icon,
            color: AppColors.navy,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _ContractsBackdrop extends StatelessWidget {
  const _ContractsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -145,
              right: -115,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -125,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withOpacity(0.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractsShimmer extends StatelessWidget {
  const _ContractsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 11),
      itemBuilder: (_, __) {
        return Container(
          height: 178,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(15),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerLine(width: 190, height: 15),
              SizedBox(height: 10),
              _ShimmerLine(width: 130, height: 10),
              SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _ShimmerLine(height: 49)),
                  SizedBox(width: 8),
                  Expanded(child: _ShimmerLine(height: 49)),
                ],
              ),
              SizedBox(height: 10),
              _ShimmerLine(height: 36),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({
    this.width = double.infinity,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F6),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

_ContractVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _ContractVisual(
        AppColors.blue,
        AppColors.blueBg,
      );
    case 'active':
    case 'in_progress':
      return const _ContractVisual(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'submitted':
      return const _ContractVisual(
        AppColors.orange,
        AppColors.orangeBg,
      );
    case 'completed':
      return const _ContractVisual(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'cancelled':
    case 'terminated':
    case 'rejected':
      return const _ContractVisual(
        AppColors.red,
        AppColors.redBg,
      );
    default:
      return const _ContractVisual(
        AppColors.blue,
        AppColors.blueBg,
      );
  }
}

class _ContractVisual {
  final Color foreground;
  final Color background;

  const _ContractVisual(
    this.foreground,
    this.background,
  );
}
