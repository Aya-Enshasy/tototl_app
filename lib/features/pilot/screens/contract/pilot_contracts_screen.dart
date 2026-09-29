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

class _PilotContractsScreenState extends State<PilotContractsScreen> {
  late final PilotContractController _controller;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String _filter = '';

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
    unawaited(_load());
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ContractsBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _filtersBar(),
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('My Contracts'),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLanguage.text(
                    'Review and manage your mission agreements',
                  ),
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _refreshing
              ? const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                )
              : _CircleButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => _load(refresh: true),
                ),
        ],
      ),
    );
  }

  Widget _filtersBar() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final item = _filters[index];
          final selected = _filter == item.value;

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(AppLanguage.text(item.label)),
            onSelected: (_) => _changeFilter(item.value),
            selectedColor: AppColors.navy,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? AppColors.navy
                  : AppColors.cardBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.grey,
              fontSize: 10.5,
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.028),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contract #${contract.id}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Job #${contract.jobPostingId} · Application #${contract.jobApplicationId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: contract.statusLabel,
                    foreground: visual.foreground,
                    background: visual.background,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      icon: Icons.payments_outlined,
                      label: 'Value',
                      value: contract.amountLabel,
                      accent: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      icon: Icons.tune_rounded,
                      label: 'Payment',
                      value: contract.paymentTypeLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        contract.dateRangeLabel,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.lightGrey,
                      size: 12,
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
