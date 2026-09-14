import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/navigation/company_shell_screen.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/user_session_storage.dart';
 import '../../../pilot/screens/notification/NotificationsScreen.dart';
import '../../../pilot/services/company_dashboard_service.dart';
 import '../../controllers/company_dashboard_controller.dart';
import '../../models/company_dashboard_model.dart';
import '../../services/company_job_service.dart';
 import '../jobs/company_job_detail_screen.dart';
import '../jobs/post_job_screen.dart';
import '../operations/company_applicant_detail_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen>
    with SingleTickerProviderStateMixin {
  static const FlutterSecureStorage _cacheStorage = FlutterSecureStorage();
  static const String _dashboardCachePrefix = 'company_home_dashboard_v2_';

  late final CompanyDashboardController _controller;
  late final AnimationController _entrance;

  _CompanyDashboardUiSnapshot? _dashboardSnapshot;
  String? _dashboardCacheKey;
  String? _dashboardError;

  bool _cacheReadFinished = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;

  String _companyName = 'Company Account';
  String _profilePhotoUrl = '';
  bool _verified = false;

  @override
  void initState() {
    super.initState();

    _controller = CompanyDashboardController(
      CompanyDashboardService(ApiClient()),
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();

    // Local-first: paint the previous dashboard immediately, then ask the API
    // for the newest version without blocking the user on every visit.
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadCompanyIdentity(),
      _loadCachedDashboard(),
    ]);

    if (!mounted) return;
    unawaited(_refreshDashboardFromNetwork(initial: true));
  }

  Future<void> _loadCompanyIdentity() async {
    final profile = await UserSessionStorage.getProfile();
    final status = await UserSessionStorage.getStatus();
    final storedPhoto = await UserSessionStorage.getProfilePhotoUrl();

    final profileName = profile?['company_name']?.toString().trim() ?? '';
    final fallbackName = profile?['name']?.toString().trim() ?? '';
    final profilePhoto = profile?['profile_photo']?.toString().trim() ?? '';
    final alternatePhoto =
        profile?['profile_photo_url']?.toString().trim() ?? '';

    final statusValue = status?.trim().toLowerCase() ?? '';
    final profileVerified = _asBool(profile?['verified']);

    if (!mounted) return;

    setState(() {
      if (profileName.isNotEmpty) {
        _companyName = profileName;
      } else if (fallbackName.isNotEmpty) {
        _companyName = fallbackName;
      }

      if (profilePhoto.isNotEmpty) {
        _profilePhotoUrl = profilePhoto;
      } else if (alternatePhoto.isNotEmpty) {
        _profilePhotoUrl = alternatePhoto;
      } else if (storedPhoto != null && storedPhoto.trim().isNotEmpty) {
        _profilePhotoUrl = storedPhoto.trim();
      }

      _verified = profileVerified ||
          statusValue == 'active' ||
          statusValue == 'approved' ||
          statusValue == 'verified';
    });
  }

  Future<void> _loadCachedDashboard() async {
    try {
      final userId = await UserSessionStorage.getUserId();
      final key = '$_dashboardCachePrefix${userId ?? 'unknown'}';
      _dashboardCacheKey = key;

      final raw = await _cacheStorage.read(key: key);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final cached = _CompanyDashboardUiSnapshot.fromJson(
            Map<String, dynamic>.from(decoded),
          );

          if (mounted) {
            setState(() => _dashboardSnapshot = cached);
          }
        }
      }
    } catch (_) {
      // Cache must never prevent the real API request from running.
    } finally {
      if (mounted) {
        setState(() => _cacheReadFinished = true);
      }
    }
  }

  Future<void> _saveDashboardCache(
      _CompanyDashboardUiSnapshot snapshot,
      ) async {
    try {
      var key = _dashboardCacheKey;
      if (key == null) {
        final userId = await UserSessionStorage.getUserId();
        key = '$_dashboardCachePrefix${userId ?? 'unknown'}';
        _dashboardCacheKey = key;
      }

      await _cacheStorage.write(
        key: key,
        value: jsonEncode(snapshot.toJson()),
      );
    } catch (_) {
      // A cache write failure should be invisible to the user.
    }
  }

  Future<void> _refreshDashboardFromNetwork({
    bool initial = false,
  }) async {
    if (_networkRefreshing) return;
    _networkRefreshing = true;

    try {
      if (initial) {
        await _controller.load();
      } else {
        await _controller.refresh();
      }

      final fresh = _controller.dashboard;
      if (fresh != null) {
        final snapshot = _CompanyDashboardUiSnapshot.fromDashboard(fresh);

        if (mounted) {
          setState(() {
            _dashboardSnapshot = snapshot;
            _dashboardError = null;
          });
        }

        unawaited(_saveDashboardCache(snapshot));
      } else if (mounted && _dashboardSnapshot == null) {
        setState(() {
          _dashboardError = _controller.errorMessage ??
              'Unable to load company dashboard.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardError = _controller.errorMessage ?? e.toString();
        });
      }
    } finally {
      _networkRefreshing = false;

      if (mounted) {
        setState(() => _firstNetworkAttemptFinished = true);
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait<void>([
      _refreshDashboardFromNetwork(),
      _loadCompanyIdentity(),
    ]);
  }

  Future<void> _openNotifications() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PilotNotificationsScreen(),
      ),
    );
  }

  Future<void> _openPostJob() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PostJobScreen(),
      ),
    );

    if (!mounted) return;
    unawaited(_refreshDashboardFromNetwork());
  }

  Future<void> _openManageJobs() async {
    HapticFeedback.selectionClick();

    // Switch to the Jobs tab inside the company bottom navigation instead of
    // opening CompanyJobsScreen as a separate pushed page. Replacing the
    // current shell also prevents an extra back-stack entry.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CompanyShellScreen(
          initialIndex: 1,
        ),
      ),
    );
  }

  Future<void> _openJob(int jobId) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyJobDetailScreen(jobId: jobId),
      ),
    );

    if (!mounted) return;
    unawaited(_refreshDashboardFromNetwork());
  }

  Future<void> _openApplicant(
      _CompanyDashboardApplicantSnapshot application,
      ) async {
    HapticFeedback.selectionClick();

    try {
      final applicants = await CompanyJobService(ApiClient()).getApplicants(
        application.jobPostingId,
      );

      final matches = applicants.where(
            (item) => item.pilotProfileId == application.pilotProfileId,
      );

      if (!mounted) return;

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applicant details are no longer available.'),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompanyApplicantDetailScreen(
            jobId: application.jobPostingId,
            application: matches.first,
          ),
        ),
      );

      if (!mounted) return;
      unawaited(_refreshDashboardFromNetwork());
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Unable to load applicant details.'
                : message,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _entry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.055).clamp(0.0, 0.48).toDouble();
    final end = (start + 0.48).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboardSnapshot;
    final shouldShowFirstShimmer = dashboard == null &&
        (!_cacheReadFinished || !_firstNetworkAttemptFinished);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -170,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.11),
                      AppColors.blue.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 390,
            left: -170,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withOpacity(0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: shouldShowFirstShimmer
                ? const _CompanyDashboardShimmer()
                : dashboard == null
                ? _DashboardErrorState(
              message: _dashboardError ??
                  _controller.errorMessage ??
                  'Unable to load company dashboard.',
              onRetry: () => _refreshDashboardFromNetwork(
                initial: true,
              ),
            )
                : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.blue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  115,
                ),
                children: [
                  _entry(
                    index: 0,
                    child: _CompanyHeader(
                      companyName: _companyName,
                      profilePhotoUrl: _profilePhotoUrl,
                      verified: _verified,
                      onNotificationsTap: _openNotifications,
                    ),
                  ),
                  const SizedBox(height: 17),
                  _entry(
                    index: 1,
                    child: _DashboardHero(dashboard: dashboard),
                  ),
                  const SizedBox(height: 23),
                  _entry(
                    index: 2,
                    child: const _SectionTitle(
                      title: 'Job Overview',
                      subtitle:
                      'Live status of your company job postings',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _entry(
                    index: 3,
                    child: _StatusGrid(dashboard: dashboard),
                  ),
                  const SizedBox(height: 18),
                  _entry(
                    index: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _openPostJob,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'Post New Job',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _openManageJobs,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navy,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.work_outline_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Manage Jobs',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _entry(
                    index: 5,
                    child: _SectionTitle(
                      title: 'Recent Applicants',
                      subtitle: dashboard.recentApplicants.isEmpty
                          ? 'No recent applications yet'
                          : 'Latest pilots across your job postings',
                      icon: Icons.people_alt_outlined,
                      trailing: dashboard.recentApplicants.isEmpty
                          ? null
                          : _CountBadge(
                        count:
                        dashboard.recentApplicants.length,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.recentApplicants.isEmpty)
                    _entry(
                      index: 6,
                      child: const _EmptyApplicantsCard(),
                    )
                  else
                    ...dashboard.recentApplicants
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final application = entry.value;
                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 10),
                        child: _entry(
                          index: 6 + entry.key,
                          child: _RecentApplicantCard(
                            application: application,
                            onTap: () =>
                                _openApplicant(application),
                          ),
                        ),
                      );
                    }),
                  if (_dashboardError != null ||
                      _controller.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _InlineRefreshWarning(
                      message: _dashboardError ??
                          _controller.errorMessage ??
                          'Could not refresh the latest data.',
                      onRetry: _refresh,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.companyName,
    required this.profilePhotoUrl,
    required this.verified,
    required this.onNotificationsTap,
  });

  final String companyName;
  final String profilePhotoUrl;
  final bool verified;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profilePhotoUrl.trim().isNotEmpty;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.09),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? Image.network(
                profilePhotoUrl.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CompanyAvatarFallback(
                  companyName: companyName,
                ),
              )
                  : _CompanyAvatarFallback(companyName: companyName),
            ),
            if (verified)
              Positioned(
                right: -2,
                bottom: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bg,
                      width: 2.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.24),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Dashboard',
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.90),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    verified
                        ? Icons.verified_rounded
                        : Icons.business_center_outlined,
                    color: verified ? AppColors.green : AppColors.grey,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    verified ? 'Verified company' : 'Company account',
                    style: TextStyle(
                      color: verified ? AppColors.green : AppColors.grey,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyAvatarFallback extends StatelessWidget {
  const _CompanyAvatarFallback({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9FBFB),
            Color(0xFFD4F3F4),
            Color(0xFFC4E8ED),
          ],
        ),
      ),
      child: Text(
        _initials(companyName),
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.dashboard});

  final _CompanyDashboardUiSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final incoming = dashboard.incomingApplicationsCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08223F),
            Color(0xFF0B4761),
            Color(0xFF0C8C9B),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.14),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -26,
            child: Icon(
              Icons.radar_rounded,
              color: Colors.white.withOpacity(0.075),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF8BE2DF),
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'LIVE OVERVIEW',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Your marketplace at a glance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.30,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                incoming == 0
                    ? 'Everything is clear — no applications are waiting for a decision.'
                    : '$incoming application${incoming == 1 ? '' : 's'} waiting for your decision.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      value: '${dashboard.totalJobs}',
                      label: 'Total Jobs',
                      icon: Icons.work_outline_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: Colors.white.withOpacity(0.10),
                  ),
                  Expanded(
                    child: _HeroMetric(
                      value: '$incoming',
                      label: 'Awaiting Decision',
                      icon: Icons.mark_email_unread_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8BE2DF),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 8.8,
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

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.dashboard});

  final _CompanyDashboardUiSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Draft',
                value: dashboard.draftJobs,
                icon: Icons.edit_note_rounded,
                accent: AppColors.orange,
                soft: AppColors.orangeBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Published',
                value: dashboard.publishedJobs,
                icon: Icons.public_rounded,
                accent: AppColors.green,
                soft: AppColors.greenBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Closed',
                value: dashboard.closedJobs,
                icon: Icons.lock_outline_rounded,
                accent: AppColors.blue,
                soft: AppColors.blueBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Cancelled',
                value: dashboard.cancelledJobs,
                icon: Icons.cancel_outlined,
                accent: const Color(0xFFE45252),
                soft: const Color(0xFFFFF1F1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.soft,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.028),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.075),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.blue, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.86),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count recent',
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecentApplicantCard extends StatelessWidget {
  const _RecentApplicantCard({
    required this.application,
    required this.onTap,
  });

  final _CompanyDashboardApplicantSnapshot application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(application.status);
    final pilotName = application.pilotName.trim().isEmpty
        ? 'Pilot #${application.pilotProfileId}'
        : application.pilotName.trim();
    final pilotPhoto = application.pilotPhoto.trim();
    final location = application.pilotLocation.trim().isEmpty
        ? 'Location not specified'
        : application.pilotLocation.trim();
    final jobTitle = application.jobTitle.trim().isEmpty
        ? 'Job #${application.jobPostingId}'
        : application.jobTitle.trim();
    final hasDrone = application.droneName.trim().isNotEmpty ||
        application.droneCapabilities.isNotEmpty;
    final capabilities = application.droneCapabilities.isEmpty
        ? 'No capabilities listed'
        : application.droneCapabilities.join(', ');
    final droneLine = application.droneName.trim().isEmpty
        ? capabilities
        : '${application.droneName.trim()} · $capabilities';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.026),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.blue.withOpacity(0.13),
                            AppColors.green.withOpacity(0.10),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: pilotPhoto.isNotEmpty
                          ? Image.network(
                        pilotPhoto,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _initials(pilotName),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                          : Text(
                        _initials(pilotName),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pilotName,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${application.experienceYears} yrs experience · $location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _titleCase(application.status),
                      style: TextStyle(
                        color: statusStyle.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cardBorder.withOpacity(0.8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasDrone) ...[
                            const SizedBox(height: 2),
                            Text(
                              droneLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 8.8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGrey,
                      size: 18,
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

class _EmptyApplicantsCard extends StatelessWidget {
  const _EmptyApplicantsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppColors.green,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No recent applicants',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'New pilot applications will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRefreshWarning extends StatelessWidget {
  const _InlineRefreshWarning({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 9.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 33,
              ),
              const SizedBox(height: 11),
              const Text(
                'Dashboard unavailable',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyDashboardShimmer extends StatefulWidget {
  const _CompanyDashboardShimmer();

  @override
  State<_CompanyDashboardShimmer> createState() =>
      _CompanyDashboardShimmerState();
}

class _CompanyDashboardShimmerState extends State<_CompanyDashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        Widget shimmerBox({
          required double height,
          double? width,
          double radius = 14,
        }) {
          final t = _animation.value;
          return Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(-1.65 + (3.3 * t), 0),
                end: Alignment(-0.65 + (3.3 * t), 0),
                colors: const [
                  Color(0xFFF1F5F7),
                  Color(0xFFE3ECEF),
                  Color(0xFFF1F5F7),
                ],
              ),
            ),
          );
        }

        Widget sectionHeader({double titleWidth = 120}) {
          return Row(
            children: [
              shimmerBox(height: 36, width: 36, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmerBox(height: 13, width: titleWidth, radius: 7),
                    const SizedBox(height: 6),
                    shimmerBox(height: 8, width: 165, radius: 6),
                  ],
                ),
              ),
            ],
          );
        }

        Widget statusCard() {
          return Container(
            height: 76,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE8EEF1)),
            ),
            child: Row(
              children: [
                shimmerBox(height: 39, width: 39, radius: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBox(height: 14, width: 34, radius: 6),
                      const SizedBox(height: 7),
                      shimmerBox(height: 8, width: 62, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget applicantCard() {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EEF1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    shimmerBox(height: 46, width: 46, radius: 14),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          shimmerBox(height: 12, width: 115, radius: 6),
                          const SizedBox(height: 8),
                          shimmerBox(height: 8, width: 170, radius: 6),
                        ],
                      ),
                    ),
                    shimmerBox(height: 25, width: 58, radius: 13),
                  ],
                ),
                const SizedBox(height: 12),
                shimmerBox(height: 44, radius: 14),
              ],
            ),
          );
        }

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          children: [
            Row(
              children: [
                shimmerBox(height: 54, width: 54, radius: 27),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBox(height: 8, width: 105, radius: 6),
                      const SizedBox(height: 7),
                      shimmerBox(height: 14, width: 160, radius: 7),
                      const SizedBox(height: 7),
                      shimmerBox(height: 8, width: 96, radius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                shimmerBox(height: 44, width: 44, radius: 15),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3C57).withOpacity(0.10),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerBox(height: 24, width: 105, radius: 13),
                  const SizedBox(height: 19),
                  shimmerBox(height: 14, width: 220, radius: 7),
                  const SizedBox(height: 8),
                  shimmerBox(height: 8, width: 260, radius: 6),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      shimmerBox(height: 39, width: 39, radius: 12),
                      const SizedBox(width: 9),
                      shimmerBox(height: 30, width: 80, radius: 8),
                      const Spacer(),
                      shimmerBox(height: 39, width: 39, radius: 12),
                      const SizedBox(width: 9),
                      shimmerBox(height: 30, width: 88, radius: 8),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            sectionHeader(titleWidth: 104),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: statusCard()),
                const SizedBox(width: 10),
                Expanded(child: statusCard()),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: statusCard()),
                const SizedBox(width: 10),
                Expanded(child: statusCard()),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: shimmerBox(height: 52, radius: 16)),
                const SizedBox(width: 10),
                Expanded(child: shimmerBox(height: 52, radius: 16)),
              ],
            ),
            const SizedBox(height: 28),
            sectionHeader(titleWidth: 130),
            const SizedBox(height: 12),
            applicantCard(),
            const SizedBox(height: 10),
            applicantCard(),
          ],
        );
      },
    );
  }
}

class _CompanyDashboardUiSnapshot {
  const _CompanyDashboardUiSnapshot({
    required this.draftJobs,
    required this.publishedJobs,
    required this.closedJobs,
    required this.cancelledJobs,
    required this.incomingApplicationsCount,
    required this.recentApplicants,
  });

  final int draftJobs;
  final int publishedJobs;
  final int closedJobs;
  final int cancelledJobs;
  final int incomingApplicationsCount;
  final List<_CompanyDashboardApplicantSnapshot> recentApplicants;

  int get totalJobs =>
      draftJobs + publishedJobs + closedJobs + cancelledJobs;

  factory _CompanyDashboardUiSnapshot.fromDashboard(
      CompanyDashboardModel dashboard,
      ) {
    return _CompanyDashboardUiSnapshot(
      draftJobs: dashboard.jobsByStatus.draft,
      publishedJobs: dashboard.jobsByStatus.published,
      closedJobs: dashboard.jobsByStatus.closed,
      cancelledJobs: dashboard.jobsByStatus.cancelled,
      incomingApplicationsCount: dashboard.incomingApplicationsCount,
      recentApplicants: dashboard.recentApplicants
          .map(_CompanyDashboardApplicantSnapshot.fromDashboardApplicant)
          .toList(growable: false),
    );
  }

  factory _CompanyDashboardUiSnapshot.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawApplicants = json['recent_applicants'];
    final applicants = <_CompanyDashboardApplicantSnapshot>[];

    if (rawApplicants is List) {
      for (final raw in rawApplicants) {
        if (raw is Map) {
          applicants.add(
            _CompanyDashboardApplicantSnapshot.fromJson(
              Map<String, dynamic>.from(raw),
            ),
          );
        }
      }
    }

    return _CompanyDashboardUiSnapshot(
      draftJobs: _asInt(json['draft_jobs']),
      publishedJobs: _asInt(json['published_jobs']),
      closedJobs: _asInt(json['closed_jobs']),
      cancelledJobs: _asInt(json['cancelled_jobs']),
      incomingApplicationsCount:
      _asInt(json['incoming_applications_count']),
      recentApplicants: applicants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draft_jobs': draftJobs,
      'published_jobs': publishedJobs,
      'closed_jobs': closedJobs,
      'cancelled_jobs': cancelledJobs,
      'incoming_applications_count': incomingApplicationsCount,
      'recent_applicants':
      recentApplicants.map((item) => item.toJson()).toList(),
    };
  }
}

class _CompanyDashboardApplicantSnapshot {
  const _CompanyDashboardApplicantSnapshot({
    required this.pilotProfileId,
    required this.jobPostingId,
    required this.pilotName,
    required this.pilotPhoto,
    required this.status,
    required this.experienceYears,
    required this.pilotLocation,
    required this.jobTitle,
    required this.droneName,
    required this.droneCapabilities,
  });

  final int pilotProfileId;
  final int jobPostingId;
  final String pilotName;
  final String pilotPhoto;
  final String status;
  final int experienceYears;
  final String pilotLocation;
  final String jobTitle;
  final String droneName;
  final List<String> droneCapabilities;

  factory _CompanyDashboardApplicantSnapshot.fromDashboardApplicant(
      CompanyDashboardApplicant application,
      ) {
    final pilot = application.pilotProfile;
    final job = application.jobPosting;
    final drone = application.drone;

    return _CompanyDashboardApplicantSnapshot(
      pilotProfileId: application.pilotProfileId,
      jobPostingId: application.jobPostingId,
      pilotName: pilot?.name ?? '',
      pilotPhoto: pilot?.profilePhoto ?? '',
      status: application.status,
      experienceYears: pilot?.experienceYears ?? 0,
      pilotLocation: pilot?.location ?? '',
      jobTitle: job?.title ?? '',
      droneName: drone?.displayName ?? '',
      droneCapabilities:
      List<String>.from(drone?.capabilities ?? const <String>[]),
    );
  }

  factory _CompanyDashboardApplicantSnapshot.fromJson(
      Map<String, dynamic> json,
      ) {
    final capabilities = <String>[];
    final rawCapabilities = json['drone_capabilities'];

    if (rawCapabilities is List) {
      for (final value in rawCapabilities) {
        final clean = value?.toString().trim() ?? '';
        if (clean.isNotEmpty) capabilities.add(clean);
      }
    }

    return _CompanyDashboardApplicantSnapshot(
      pilotProfileId: _asInt(json['pilot_profile_id']),
      jobPostingId: _asInt(json['job_posting_id']),
      pilotName: json['pilot_name']?.toString() ?? '',
      pilotPhoto: json['pilot_photo']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      experienceYears: _asInt(json['experience_years']),
      pilotLocation: json['pilot_location']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      droneName: json['drone_name']?.toString() ?? '',
      droneCapabilities: capabilities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pilot_profile_id': pilotProfileId,
      'job_posting_id': jobPostingId,
      'pilot_name': pilotName,
      'pilot_photo': pilotPhoto,
      'status': status,
      'experience_years': experienceYears,
      'pilot_location': pilotLocation,
      'job_title': jobTitle,
      'drone_name': droneName,
      'drone_capabilities': droneCapabilities,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'C';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _StatusStyle {
  const _StatusStyle(this.accent, this.soft);

  final Color accent;
  final Color soft;
}

_StatusStyle _statusStyle(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusStyle(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return const _StatusStyle(
        Color(0xFFE45252),
        Color(0xFFFFF1F1),
      );
    case 'withdrawn':
      return const _StatusStyle(AppColors.grey, Color(0xFFF1F4F7));
    default:
      return const _StatusStyle(AppColors.orange, AppColors.orangeBg);
  }
}

String _titleCase(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'Pending';
  return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
}
