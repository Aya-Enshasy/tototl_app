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

  Future<void> _openDetails(PilotApplicationModel application) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(
          applicationId: application.id,
          initialApplication: application,
        ),
      ),
    );

    if (mounted) {
      await _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.compact) return _compact();
        return _fullScreen();
      },
    );
  }

  Widget _compact() {
    if (_controller.isLoading) {
      return const Column(
        children: [
          _ApplicationSkeleton(height: 78),
          SizedBox(height: 10),
          _ApplicationSkeleton(height: 78),
        ],
      );
    }

    if (_controller.errorMessage != null &&
        _controller.applications.isEmpty) {
      return _CompactMessage(
        icon: Icons.cloud_off_rounded,
        text: _controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: _controller.load,
      );
    }

    if (_controller.applications.isEmpty) {
      return const _CompactMessage(
        icon: Icons.assignment_outlined,
        text: 'No applications yet.',
      );
    }

    return Column(
      children: _controller.applications
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
    );
  }

  Widget _fullScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -170,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.blue,
                          size: 21,
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
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _controller.isLoading
                                  ? 'Loading your applications...'
                                  : '${_controller.pendingCount} pending · ${_controller.totalCount} total',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    if (_controller.isLoading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (_, __) => const _ApplicationSkeleton(height: 84),
      );
    }

    if (_controller.errorMessage != null &&
        _controller.applications.isEmpty) {
      return _FullMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load applications',
        text: _controller.errorMessage!,
        actionLabel: 'Try Again',
        onAction: _controller.load,
      );
    }

    if (_controller.applications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: const _EmptyApplications(),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: _controller.applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final application = _controller.applications[index];
          return _ApplicationCard(
            application: application,
            onTap: () => _openDetails(application),
          );
        },
      ),
    );
  }
}

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
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 43 : 49,
                height: compact ? 43 : 49,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: visual.foreground,
                  size: compact ? 20 : 22,
                ),
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
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.companyLabel.isNotEmpty
                          ? application.companyLabel
                          : application.submittedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.8,
                      ),
                    ),
                    if (!compact && application.companyLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        application.submittedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.grey.withOpacity(0.75),
                          fontSize: 10.5,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      application.statusLabel,
                      style: TextStyle(
                        color: visual.foreground,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 7),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGrey,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusVisual {
  final Color foreground;
  final Color background;
  const _StatusVisual(this.foreground, this.background);
}

_StatusVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusVisual(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return const _StatusVisual(AppColors.red, AppColors.redBg);
    case 'withdrawn':
      return _StatusVisual(AppColors.grey, Colors.grey.shade100);
    default:
      return const _StatusVisual(AppColors.blue, AppColors.blueBg);
  }
}

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
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
            Icon(icon, color: AppColors.blue, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.8,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(actionLabel),
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
      padding: const EdgeInsets.fromLTRB(30, 70, 30, 100),
      children: [
        const Icon(
          Icons.assignment_outlined,
          color: AppColors.blue,
          size: 44,
        ),
        const SizedBox(height: 14),
        const Text(
          'No applications yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Applications you submit to published jobs will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.8,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ApplicationSkeleton extends StatefulWidget {
  const _ApplicationSkeleton({required this.height});
  final double height;

  @override
  State<_ApplicationSkeleton> createState() => _ApplicationSkeletonState();
}

class _ApplicationSkeletonState extends State<_ApplicationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (_, __) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              begin: Alignment(-1.6 + 3.2 * t, 0),
              end: Alignment(-0.6 + 3.2 * t, 0),
              colors: [
                Colors.grey.shade100,
                Colors.grey.shade200,
                Colors.grey.shade100,
              ],
            ),
          ),
        );
      },
    );
  }
}
