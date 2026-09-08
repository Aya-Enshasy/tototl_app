import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../controllers/pilot_application_controller.dart';
import '../../models/pilot_application_model.dart';
import '../../services/pilot_application_service.dart';
import 'application_details_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  late final PilotApplicationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PilotApplicationController(
      PilotApplicationService(ApiClient()),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetails(
      PilotApplicationModel application,
      ) async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(
          applicationId: application.id,
          initialApplication: application,
        ),
      ),
    );

    if (!mounted) return;

    // ApplicationDetailsScreen refreshes its own cached snapshot. Reuse that
    // snapshot immediately instead of issuing another request just because the
    // user navigated back.
    final cached =
    await _controller.service.getCachedApplication(application.id);

    if (!mounted) return;

    if (cached != null) {
      _controller.replaceApplication(cached);
    }

    // A mutation such as Withdraw deserves one authoritative list refresh.
    if (changed == true) {
      await _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return widget.compact ? _compact() : _fullScreen();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HOME / COMPACT VERSION
  // ---------------------------------------------------------------------------

  Widget _compact() {
    final applications = _controller.applications;

    if (_controller.isLoading && applications.isEmpty) {
      return const _ApplicationsShimmer(compact: true);
    }

    if (_controller.errorMessage != null && applications.isEmpty) {
      return _CompactMessage(
        icon: Icons.cloud_off_rounded,
        text: _controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: _controller.load,
      );
    }

    if (applications.isEmpty) {
      return const _CompactMessage(
        icon: Icons.assignment_outlined,
        text: 'No applications yet.',
      );
    }

    return Stack(
      children: [
        Column(
          children: applications
              .take(2)
              .map(
                (application) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ApplicationCard(
                application: application,
                compact: true,
                onTap: () => _openDetails(application),
              ),
            ),
          )
              .toList(),
        ),
        if (_controller.isRefreshing)
          const Positioned(
            right: 8,
            top: 8,
            child: _UpdatingDot(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FULL SCREEN
  // ---------------------------------------------------------------------------

  Widget _fullScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ScreenBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _PremiumHeader(
                  total: _controller.totalCount,
                  pending: _controller.pendingCount,
                  accepted: _controller.acceptedCount,
                  refreshing: _controller.isRefreshing,
                  loading: _controller.isLoading &&
                      _controller.applications.isEmpty,
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final applications = _controller.applications;

    if (_controller.isLoading && applications.isEmpty) {
      return const _ApplicationsShimmer();
    }

    if (_controller.errorMessage != null && applications.isEmpty) {
      return _FullMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load applications',
        text: _controller.errorMessage!,
        actionLabel: 'Try Again',
        onAction: _controller.load,
      );
    }

    if (applications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.logoTurquoiseDark,
        onRefresh: _controller.refresh,
        child: const _EmptyApplications(),
      );
    }

    return RefreshIndicator(
      color: AppColors.logoTurquoiseDark,
      backgroundColor: Colors.white,
      onRefresh: _controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 110),
        itemCount: applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final application = applications[index];
          return _ApplicationCard(
            application: application,
            onTap: () => _openDetails(application),
          );
        },
      ),
    );
  }
}

// =============================================================================
// BACKDROP
// =============================================================================

class _ScreenBackdrop extends StatelessWidget {
  const _ScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -125,
          child: Container(
            width: 330,
            height: 330,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF16C6C7).withOpacity(0.11),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 260,
          left: -140,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blue.withOpacity(0.045),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.refreshing,
    required this.loading,
  });

  final int total;
  final int pending;
  final int accepted;
  final bool refreshing;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE7FBFB),
                      Color(0xFFEAF3FA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF16C6C7).withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.logoTurquoiseDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Applications',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      loading
                          ? 'Preparing your application history'
                          : total == 0
                          ? 'Your submitted jobs will appear here'
                          : '$pending pending · $accepted accepted',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: refreshing
                    ? const _UpdatingPill(key: ValueKey('updating'))
                    : const SizedBox(
                  key: ValueKey('idle'),
                  width: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatsBar(
            total: total,
            pending: pending,
            accepted: accepted,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.loading,
  });

  final int total;
  final int pending;
  final int accepted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.layers_outlined,
              label: 'Total',
              value: loading ? '—' : '$total',
              color: AppColors.blue,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.schedule_rounded,
              label: 'Pending',
              value: loading ? '—' : '$pending',
              color: const Color(0xFFE99A18),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Accepted',
              value: loading ? '—' : '$accepted',
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: AppColors.cardBorder,
    );
  }
}

class _UpdatingPill extends StatelessWidget {
  const _UpdatingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FAFA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF16C6C7).withOpacity(0.12),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UpdatingDot(),
          SizedBox(width: 6),
          Text(
            'Updating',
            style: TextStyle(
              color: AppColors.logoTurquoiseDark,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatingDot extends StatefulWidget {
  const _UpdatingDot({super.key});

  @override
  State<_UpdatingDot> createState() => _UpdatingDotState();
}

class _UpdatingDotState extends State<_UpdatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.logoTurquoiseDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// =============================================================================
// APPLICATION CARD
// =============================================================================

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
    this.compact = false,
  });

  final PilotApplicationModel application;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(application.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 21),
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 11 : 13,
            compact ? 10 : 12,
            compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFBFDFE),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 18 : 21),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.85,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(compact ? 0.025 : 0.045),
                blurRadius: compact ? 12 : 20,
                offset: Offset(0, compact ? 4 : 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: compact ? 44 : 50,
                    height: compact ? 44 : 50,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(compact ? 13 : 15),
                    ),
                    child: Icon(
                      visual.icon,
                      color: visual.foreground,
                      size: compact ? 20 : 22,
                    ),
                  ),
                  Positioned(
                    left: -1,
                    top: 9,
                    bottom: 9,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: visual.foreground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: compact ? 13.5 : 14.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (application.companyLabel.isNotEmpty)
                      _MetaLine(
                        icon: Icons.business_outlined,
                        text: application.companyLabel,
                        compact: compact,
                      ),
                    if (!compact || application.companyLabel.isEmpty) ...[
                      SizedBox(height: compact ? 2 : 4),
                      _MetaLine(
                        icon: Icons.schedule_rounded,
                        text: application.submittedLabel,
                        compact: compact,
                        lighter: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 9,
                      vertical: compact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      application.statusLabel,
                      style: TextStyle(
                        color: visual.foreground,
                        fontSize: compact ? 9.2 : 9.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  Container(
                    width: compact ? 26 : 29,
                    height: compact ? 26 : 29,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.blue,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.compact,
    this.lighter = false,
  });

  final IconData icon;
  final String text;
  final bool compact;
  final bool lighter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 10.5 : 11.5,
          color: AppColors.grey.withOpacity(lighter ? 0.55 : 0.75),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.grey.withOpacity(lighter ? 0.65 : 0.9),
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusVisual {
  final Color foreground;
  final Color background;
  final IconData icon;

  const _StatusVisual(
      this.foreground,
      this.background,
      this.icon,
      );
}

_StatusVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusVisual(
        AppColors.green,
        AppColors.greenBg,
        Icons.verified_rounded,
      );
    case 'rejected':
      return const _StatusVisual(
        AppColors.red,
        AppColors.redBg,
        Icons.close_rounded,
      );
    case 'withdrawn':
      return _StatusVisual(
        AppColors.grey,
        Colors.grey.shade100,
        Icons.undo_rounded,
      );
    default:
      return const _StatusVisual(
        Color(0xFFE99A18),
        Color(0xFFFFF4E5),
        Icons.schedule_rounded,
      );
  }
}

// =============================================================================
// STATES
// =============================================================================

class _CompactMessage extends StatelessWidget {
  const _CompactMessage({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.blueBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.blue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.8,
                height: 1.35,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _FullMessage extends StatelessWidget {
  const _FullMessage({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.blueBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.blue, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.logoTurquoiseDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 72, 30, 120),
      children: [
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE7FAFA), Color(0xFFF0F6FA)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.send_time_extension_outlined,
              color: AppColors.logoTurquoiseDark,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Your opportunities start here',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Applications you submit to published jobs will appear here with their latest status.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PREMIUM STRUCTURED SHIMMER
// =============================================================================

class _ApplicationsShimmer extends StatefulWidget {
  const _ApplicationsShimmer({this.compact = false});

  final bool compact;

  @override
  State<_ApplicationsShimmer> createState() =>
      _ApplicationsShimmerState();
}

class _ApplicationsShimmerState extends State<_ApplicationsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.compact) {
          return Column(
            children: [
              _card(compact: true),
              const SizedBox(height: 10),
              _card(compact: true),
            ],
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 110),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 11),
          itemBuilder: (_, __) => _card(),
        );
      },
    );
  }

  Widget _card({bool compact = false}) {
    return Container(
      height: compact ? 76 : 92,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 21),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _glow(
            width: compact ? 44 : 50,
            height: compact ? 44 : 50,
            radius: compact ? 13 : 15,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _glow(width: 150, height: 12, radius: 6),
                const SizedBox(height: 8),
                _glow(width: 110, height: 8, radius: 5),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  _glow(width: 82, height: 7, radius: 5),
                ],
              ],
            ),
          ),
          const SizedBox(width: 9),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _glow(width: 58, height: 21, radius: 11),
              const SizedBox(height: 8),
              _glow(width: 26, height: 26, radius: 13),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glow({
    required double width,
    required double height,
    required double radius,
  }) {
    final t = _controller.value;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * t), 0),
          end: Alignment(-0.8 + (3.6 * t), 0),
          colors: const [
            Color(0xFFEEF4F5),
            Color(0xFFFAFCFD),
            Color(0xFFE3F0F2),
            Color(0xFFFAFCFD),
            Color(0xFFEEF4F5),
          ],
        ),
      ),
    );
  }
}
