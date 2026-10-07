import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import '../../../../core/navigation/company_shell_screen.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../pilot/screens/notification/NotificationsScreen.dart';
import '../../../pilot/services/company_dashboard_service.dart';
import '../../controllers/company_dashboard_controller.dart';
import '../../models/company_dashboard_model.dart';
import '../../services/CompanyProfileSync.dart';
import '../../services/company_job_service.dart';
import '../jobs/company_job_detail_screen.dart';
import '../jobs/post_job_screen.dart';
import '../applications/company_applicant_detail_screen.dart';

import 'package:tototl_app/features/payments/screens/payment_history_screen.dart';
import 'package:tototl_app/features/payments/services/payment_service.dart';
import 'package:tototl_app/features/company/screens/contract/company_contracts_screen.dart';
import 'package:tototl_app/features/shared/models/phase3_account_summary.dart';
import 'package:tototl_app/features/shared/services/phase3_dashboard_service.dart';
import 'package:tototl_app/features/subscriptions/screens/subscription_center_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const FlutterSecureStorage _cacheStorage = FlutterSecureStorage();
  static const String _dashboardCachePrefix = 'company_home_dashboard_v2_';

  late final CompanyDashboardController _controller;
  late final AnimationController _entrance;
  late final Phase3DashboardService _phase3Service;
  late final CompanyProfileSync _profileSync;

  Timer? _liveRefreshTimer;
  bool _identityReloadQueued = false;

  Phase3AccountSummary _phase3Summary = const Phase3AccountSummary();
  bool _phase3Loading = true;
  bool _phase3HasSnapshot = false;
  String? _phase3Error;

  _CompanyDashboardUiSnapshot? _dashboardSnapshot;
  String? _dashboardCacheKey;
  String? _dashboardError;

  bool _cacheReadFinished = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;

  String _companyName = 'Company Account';
  String _profilePhotoUrl = '';
  String _companyMeta = 'Active account';
  bool _verified = false;

  @override
  void initState() {
    super.initState();

    _controller = CompanyDashboardController(
      CompanyDashboardService(ApiClient()),
    );

    _profileSync = CompanyProfileSync.instance;
    UserSessionStorage.revision.addListener(_onSessionRevision);
    WidgetsBinding.instance.addObserver(this);

    _phase3Service = Phase3DashboardService(
      ApiClient(),
      audience: Phase3DashboardAudience.company,
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();

    // Local-first: paint the previous dashboard immediately, then ask the API
    // for the newest version without blocking the user on every visit.
    unawaited(_bootstrap());
    unawaited(_loadPhase3());
    _startLiveRefresh();
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!_canAutoRefresh) return;
        unawaited(_refreshLiveData());
      },
    );
  }

  bool get _canAutoRefresh {
    if (!mounted) return false;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    // CompanyShell may keep tabs alive. When the shell disables tickers for an
    // inactive tab, do not poll from that hidden tab.
    if (!TickerMode.of(context)) return false;

    return true;
  }

  Future<void> _refreshLiveData() async {
    if (!_canAutoRefresh) return;

    await Future.wait<void>([
      _refreshDashboardFromNetwork(),
      _loadPhase3(),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    scheduleMicrotask(() {
      if (_canAutoRefresh) {
        unawaited(_refreshLiveData());
      }
    });
  }

  Future<void> _loadPhase3() async {
    if (_phase3Loading && _phase3HasSnapshot) return;

    if (mounted) {
      setState(() {
        _phase3Loading = true;
        _phase3Error = null;
      });
    }

    try {
      final overview = await _phase3Service.getOverview();
      if (!mounted) return;
      setState(() {
        _phase3Summary = overview;
        _phase3HasSnapshot = true;
        _phase3Error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase3Error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _phase3Loading = false);
      }
    }
  }

  Future<void> _openPhase3Contracts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanyContractsScreen()),
    );
    if (mounted) unawaited(_loadPhase3());
  }

  Future<void> _openPhase3Payments() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaymentHistoryScreen(
          audience: PaymentAudience.company,
        ),
      ),
    );

    if (mounted) {
      unawaited(_loadPhase3());
    }
  }

  Future<void> _openSubscriptionCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionCenterScreen()),
    );
    if (mounted) unawaited(_loadPhase3());
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadCompanyIdentity(),
      _loadCachedDashboard(),
    ]);

    if (!mounted) return;

    // Start both network refreshes only AFTER cached/local UI is painted.
    unawaited(_profileSync.refreshFromApi());
    unawaited(_refreshDashboardFromNetwork(initial: true));
  }

  void _onSessionRevision() {
    if (!mounted || _identityReloadQueued) return;
    _identityReloadQueued = true;

    scheduleMicrotask(() async {
      _identityReloadQueued = false;
      if (!mounted) return;
      await _loadCompanyIdentity();
    });
  }

  Future<void> _loadCompanyIdentity() async {
    final session = await UserSessionStorage.getSession();

    final rawProfile = session?['profile'];
    final profile = rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : <String, dynamic>{};

    final rawUser = session?['user'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};

    final profileName =
        profile['company_name']?.toString().trim() ?? '';
    final profileFallbackName =
        profile['name']?.toString().trim() ?? '';
    final userFallbackName =
        user['name']?.toString().trim() ?? '';

    final profilePhoto =
        profile['profile_photo']?.toString().trim() ?? '';
    final alternatePhoto =
        profile['profile_photo_url']?.toString().trim() ?? '';
    final storedPhoto =
        session?['profile_photo_url']?.toString().trim() ?? '';

    final statusValue =
        user['status']?.toString().trim().toLowerCase() ?? '';

    final profileVerified = _asBool(profile['verified']);

    if (!mounted) return;

    setState(() {
      if (profileName.isNotEmpty) {
        _companyName = profileName;
      } else if (profileFallbackName.isNotEmpty) {
        _companyName = profileFallbackName;
      } else if (userFallbackName.isNotEmpty) {
        _companyName = userFallbackName;
      }

      if (profilePhoto.isNotEmpty) {
        _profilePhotoUrl = profilePhoto;
      } else if (alternatePhoto.isNotEmpty) {
        _profilePhotoUrl = alternatePhoto;
      } else if (storedPhoto.isNotEmpty) {
        _profilePhotoUrl = storedPhoto;
      } else {
        _profilePhotoUrl = '';
      }

      _verified = profileVerified ||
          statusValue == 'active' ||
          statusValue == 'approved' ||
          statusValue == 'verified';

      _companyMeta = _buildCompanyMeta(
        profile.isEmpty ? null : profile,
        statusValue,
      );
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
      _loadPhase3(),
      _profileSync.refreshFromApi(force: true).then((_) {}),
    ]);

    // The profile sync writes to session storage and therefore also triggers
    // the revision listener. Read once here as a deterministic final step for
    // the pull-to-refresh completion.
    await _loadCompanyIdentity();
  }

  Future<void> _openNotifications() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PilotNotificationsScreen(),
      ),
    );

    if (mounted) {
      unawaited(_refreshLiveData());
    }
  }

  Future<void> _openPostJob() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>   PostJobScreen(),
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
          SnackBar(
            content: Text(AppLanguage.text('Applicant details are no longer available.')),
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
    _liveRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    UserSessionStorage.revision.removeListener(_onSessionRevision);
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
      backgroundColor: _HomePalette.background,
      body: SafeArea(
        child: shouldShowFirstShimmer
            ? const _CompanyHomeReferenceShimmer()
            : dashboard == null
            ? _DashboardErrorState(
          message: _dashboardError ??
              _controller.errorMessage ??
              'Unable to load company dashboard.',
          onRetry: () => _refreshDashboardFromNetwork(initial: true),
        )
            : RefreshIndicator(
          color: _HomePalette.teal,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 115),
            children: [
              _entry(
                index: 0,
                child: _ReferenceCompanyHeader(
                  companyName: _companyName,
                  profilePhotoUrl: _profilePhotoUrl,
                  verified: _verified,
                  companyMeta: _companyMeta,
                  onNotificationsTap: _openNotifications,
                ),
              ),
              const SizedBox(height: 18),
              _entry(
                index: 1,
                child: _ReferenceGreeting(companyName: _companyName),
              ),
              const SizedBox(height: 18),
              _entry(
                index: 2,
                child: _PostJobBanner(onTap: _openPostJob),
              ),
              const SizedBox(height: 14),
              _entry(
                index: 3,
                child: _AttentionCard(
                  dashboard: dashboard,
                  onManageJobs: _openManageJobs,
                ),
              ),
              const SizedBox(height: 14),
              _entry(
                index: 4,
                child: _DashboardQuickStats(dashboard: dashboard),
              ),
              const SizedBox(height: 14),
              _entry(
                index: 5,
                child: _CompanyPaymentsShortcut(
                  onTap: _openPhase3Payments,
                ),
              ),
              const SizedBox(height: 18),
              _entry(
                index: 6,
                child: _CompactSectionHeader(
                  title: 'Active mission',
                  actionText: 'View all',
                  onActionTap: dashboard.recentApplicants.isEmpty
                      ? _openManageJobs
                      : () => _openJob(dashboard.recentApplicants.first.jobPostingId),
                ),
              ),
              const SizedBox(height: 10),
              _entry(
                index: 7,
                child: _ActiveMissionPreview(
                  dashboard: dashboard,
                  onTap: dashboard.recentApplicants.isEmpty
                      ? _openManageJobs
                      : () => _openJob(dashboard.recentApplicants.first.jobPostingId),
                ),
              ),
              const SizedBox(height: 18),
              _entry(
                index: 8,
                child: _CompactSectionHeader(
                  title: 'Recent applicants',
                  actionText: dashboard.recentApplicants.isEmpty
                      ? null
                      : 'View all',
                  onActionTap: dashboard.recentApplicants.isEmpty
                      ? null
                      : _openManageJobs,
                ),
              ),
              const SizedBox(height: 8),
              _entry(
                index: 9,
                child: dashboard.recentApplicants.isEmpty
                    ? const _ReferenceEmptyApplicants()
                    : _ReferenceApplicantsCard(
                  applicants: dashboard.recentApplicants.take(2).toList(),
                  onApplicantTap: _openApplicant,
                ),
              ),
              if (_dashboardError != null ||
                  _controller.errorMessage != null) ...[
                const SizedBox(height: 12),
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
    );
  }
}


class _CompanyPaymentsShortcut extends StatelessWidget {
  const _CompanyPaymentsShortcut({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            12,
            11,
            10,
            11,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _HomePalette.line,
            ),
            boxShadow: [
              BoxShadow(
                color: _HomePalette.navy.withOpacity(.025),
                blurRadius: 16,
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
                  color: const Color(0xFFE7F8F7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _HomePalette.tealDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments',
                      style: TextStyle(
                        color: _HomePalette.navy,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Funding, releases and payment history',
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 9.4,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _HomePalette.paleBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _HomePalette.tealDark,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePalette {
  static const background = Color(0xFFF9FCFD);
  static const navy = Color(0xFF082A43);
  static const text = Color(0xFF12334A);
  static const muted = Color(0xFF738598);
  static const teal = Color(0xFF17A5B8);
  static const tealDark = Color(0xFF1194A7);
  static const mint = Color(0xFF39C6BC);
  static const line = Color(0xFFE6EDF0);
  static const paleBlue = Color(0xFFF1F8FA);
  static const paleMint = Color(0xFFECFBF8);
  static const paleOrange = Color(0xFFFFF5EC);
  static const orange = Color(0xFFFF7958);
  static const danger = Color(0xFFE75A5A);
  static const skin = Color(0xFFD8A684);
  static const skinSoft = Color(0xFFFFF4EB);
}

class _ReferenceCompanyHeader extends StatelessWidget {
  const _ReferenceCompanyHeader({
    required this.companyName,
    required this.profilePhotoUrl,
    required this.verified,
    required this.companyMeta,
    required this.onNotificationsTap,
  });

  final String companyName;
  final String profilePhotoUrl;
  final bool verified;
  final String companyMeta;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profilePhotoUrl.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _HomePalette.navy.withOpacity(.10),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.network(
                  profilePhotoUrl.trim(),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) =>
                      _ReferenceAvatarFallback(name: companyName),
                )
                    : _ReferenceAvatarFallback(name: companyName),
              ),
            ),
            Positioned(
              right: -1,
              bottom: 1,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: _HomePalette.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
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
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.navy,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: _HomePalette.skin,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      companyMeta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.skin,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _HomePalette.line),
                boxShadow: [
                  BoxShadow(
                    color: _HomePalette.navy.withOpacity(.035),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: _HomePalette.navy,
                    size: 24,
                  ),
                  Positioned(
                    right: 11,
                    top: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _HomePalette.mint,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
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

class _ReferenceAvatarFallback extends StatelessWidget {
  const _ReferenceAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF65B7C4), Color(0xFF0E6579)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReferenceGreeting extends StatelessWidget {
  const _ReferenceGreeting({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final displayName = _firstDisplayName(companyName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $displayName',
          style: const TextStyle(
            color: _HomePalette.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          "Here's what's happening with your jobs today.",
          style: TextStyle(
            color: _HomePalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _PostJobBanner extends StatelessWidget {
  const _PostJobBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_HomePalette.teal, Color(0xFF149CB1)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _HomePalette.teal.withOpacity(.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Post a job',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.dashboard,
    required this.onManageJobs,
  });

  final _CompanyDashboardUiSnapshot dashboard;
  final VoidCallback onManageJobs;

  @override
  Widget build(BuildContext context) {
    final incoming = dashboard.incomingApplicationsCount;
    final hasAttention = incoming > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _HomePalette.line),
        boxShadow: [
          BoxShadow(
            color: _HomePalette.navy.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onManageJobs,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: hasAttention
                          ? _HomePalette.orange
                          : _HomePalette.mint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (hasAttention
                              ? _HomePalette.orange
                              : _HomePalette.mint)
                              .withOpacity(.24),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      hasAttention
                          ? '$incoming need your attention'
                          : 'You are all caught up',
                      style: const TextStyle(
                        color: _HomePalette.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: _HomePalette.muted),
                ],
              ),
            ),
          ),
          if (hasAttention) ...[
            const Divider(height: 1, thickness: .7, color: _HomePalette.line),
            _AttentionRow(
              icon: Icons.description_outlined,
              iconColor: _HomePalette.orange,
              iconBackground: _HomePalette.paleOrange,
              title: 'New pilot application',
              subtitle: incoming == 1
                  ? 'aya applied to your latest job'
                  : 'Latest pilots are applying to your jobs',
              trailing: incoming == 1 ? '2h ago' : '2h ago',
              onTap: onManageJobs,
            ),
            const Divider(height: 1, thickness: .7, color: _HomePalette.line),
            _AttentionRow(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: _HomePalette.tealDark,
              iconBackground: _HomePalette.paleMint,
              title: 'Work submitted',
              subtitle: 'Mission #M-102 completed',
              trailing: '5h ago',
              onTap: onManageJobs,
            ),
          ] else ...[
            const Divider(height: 1, thickness: .7, color: _HomePalette.line),
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 11, 15, 13),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 20, color: _HomePalette.mint),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No applications need a decision right now.',
                      style: TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _HomePalette.navy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomePalette.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: const TextStyle(
                color: _HomePalette.muted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardQuickStats extends StatelessWidget {
  const _DashboardQuickStats({required this.dashboard});

  final _CompanyDashboardUiSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            value: '${dashboard.publishedJobs}',
            label: 'Open jobs',
            icon: Icons.work_outline_rounded,
            iconColor: _HomePalette.teal,
            background: _HomePalette.paleBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickStatCard(
            value: '${dashboard.totalJobs}',
            label: 'Active missions',
            icon: Icons.flight_takeoff_rounded,
            iconColor: _HomePalette.mint,
            background: _HomePalette.paleMint,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickStatCard(
            value: '${dashboard.incomingApplicationsCount}',
            label: 'Awaiting review',
            icon: Icons.description_outlined,
            iconColor: _HomePalette.orange,
            background: _HomePalette.paleOrange,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(13, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _HomePalette.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomePalette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSectionHeader extends StatelessWidget {
  const _CompactSectionHeader({
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _HomePalette.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: _HomePalette.tealDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveMissionPreview extends StatelessWidget {
  const _ActiveMissionPreview({
    required this.dashboard,
    required this.onTap,
  });

  final _CompanyDashboardUiSnapshot dashboard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recent = dashboard.recentApplicants.isEmpty
        ? null
        : dashboard.recentApplicants.first;
    final title = recent == null || recent.jobTitle.trim().isEmpty
        ? 'No active mission yet'
        : recent.jobTitle.trim();
    final pilotName = recent == null || recent.pilotName.trim().isEmpty
        ? 'Pilot not assigned'
        : recent.pilotName.trim();
    final location = recent == null || recent.pilotLocation.trim().isEmpty
        ? 'Location not specified'
        : recent.pilotLocation.trim();
    final imageUrl = recent == null ? '' : recent.pilotPhoto.trim();
    final hasMission = recent != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _HomePalette.line),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 132,
                    height: 84,
                    color: const Color(0xFFEAF1F4),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _MissionImageFallback(hasMission: hasMission),
                    )
                        : _MissionImageFallback(hasMission: hasMission),
                  ),
                ),
                if (hasMission)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF9F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'In progress',
                        style: TextStyle(
                          color: _HomePalette.tealDark,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.navy,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasMission ? 'With $pilotName' : 'Publish a job to get started',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 10.5,
                      ),
                    ),
                    const Spacer(),
                    _GradientProgressBar(
                      value: hasMission ? .60 : 0,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: _HomePalette.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _HomePalette.muted,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        if (hasMission) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: _HomePalette.muted),
                          const SizedBox(width: 4),
                          const Text(
                            '3 days left',
                            style: TextStyle(
                              color: _HomePalette.muted,
                              fontSize: 10.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionImageFallback extends StatelessWidget {
  const _MissionImageFallback({required this.hasMission});

  final bool hasMission;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D91A0), Color(0xFF1A516A)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        hasMission ? Icons.solar_power_outlined : Icons.flight_takeoff_rounded,
        color: Colors.white.withOpacity(.92),
        size: 30,
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = (totalWidth * value).clamp(0.0, totalWidth);
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFE4EBEF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: filledWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0F7FB6), Color(0xFF10A7C6), Color(0xFF38D0C7)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _ReferenceApplicantsCard extends StatelessWidget {
  const _ReferenceApplicantsCard({
    required this.applicants,
    required this.onApplicantTap,
  });

  final List<_CompanyDashboardApplicantSnapshot> applicants;
  final Future<void> Function(_CompanyDashboardApplicantSnapshot) onApplicantTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.line),
      ),
      child: Column(
        children: applicants.asMap().entries.map((entry) {
          final index = entry.key;
          final application = entry.value;
          return Column(
            children: [
              _ReferenceApplicantRow(
                application: application,
                onTap: () { unawaited(onApplicantTap(application)); },
              ),
              if (index != applicants.length - 1)
                const Divider(
                  height: 1,
                  thickness: .7,
                  indent: 16,
                  endIndent: 16,
                  color: _HomePalette.line,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ReferenceApplicantRow extends StatelessWidget {
  const _ReferenceApplicantRow({
    required this.application,
    required this.onTap,
  });

  final _CompanyDashboardApplicantSnapshot application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pilotName = application.pilotName.trim().isEmpty
        ? 'Pilot #${application.pilotProfileId}'
        : application.pilotName.trim();
    final pilotPhoto = application.pilotPhoto.trim();
    final capabilities = application.droneCapabilities.take(2).join(', ');
    final details = [
      '${application.experienceYears} yrs experience',
      if (capabilities.isNotEmpty) capabilities,
    ].join(' · ');
    final style = _statusStyle(application.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFB8E2E6), Color(0xFF4E92A1)],
                  ),
                ),
                child: ClipOval(
                  child: pilotPhoto.isEmpty
                      ? Center(
                    child: Text(
                      _initials(pilotName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                      : Image.network(
                    pilotPhoto,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        _initials(pilotName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilotName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: style.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _titleCase(application.status),
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceEmptyApplicants extends StatelessWidget {
  const _ReferenceEmptyApplicants();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.people_outline_rounded,
              color: _HomePalette.teal, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'New pilot applications will appear here.',
              style: TextStyle(
                color: _HomePalette.muted,
                fontSize: 11.5,
              ),
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
        color: _HomePalette.paleOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: _HomePalette.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomePalette.text,
                fontSize: 10.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: _HomePalette.tealDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomePalette.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: _HomePalette.teal, size: 30),
              const SizedBox(height: 10),
              const Text(
                'Dashboard unavailable',
                style: TextStyle(
                  color: _HomePalette.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _HomePalette.muted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: _HomePalette.teal,
                  textStyle: const TextStyle(fontSize: 12),
                ),
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

class _CompanyHomeReferenceShimmer extends StatefulWidget {
  const _CompanyHomeReferenceShimmer();

  @override
  State<_CompanyHomeReferenceShimmer> createState() =>
      _CompanyHomeReferenceShimmerState();
}

class _CompanyHomeReferenceShimmerState
    extends State<_CompanyHomeReferenceShimmer>
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
        Widget box(double h, {double? w, double r = 14}) {
          final t = _controller.value;
          return Container(
            width: w ?? double.infinity,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              gradient: LinearGradient(
                begin: Alignment(-1.8 + (3.6 * t), 0),
                end: Alignment(-.8 + (3.6 * t), 0),
                colors: const [
                  Color(0xFFF1F5F6),
                  Color(0xFFE4ECEE),
                  Color(0xFFF1F5F6),
                ],
              ),
            ),
          );
        }

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 115),
          children: [
            Row(
              children: [
                box(58, w: 58, r: 29),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(14, w: 150, r: 7),
                      const SizedBox(height: 8),
                      box(10, w: 105, r: 6),
                    ],
                  ),
                ),
                box(48, w: 48, r: 18),
              ],
            ),
            const SizedBox(height: 20),
            box(16, w: 210, r: 7),
            const SizedBox(height: 8),
            box(11, w: 245, r: 6),
            const SizedBox(height: 18),
            box(55, r: 15),
            const SizedBox(height: 14),
            box(122, r: 17),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: box(104, r: 16)),
                const SizedBox(width: 8),
                Expanded(child: box(104, r: 16)),
                const SizedBox(width: 8),
                Expanded(child: box(104, r: 16)),
              ],
            ),
            const SizedBox(height: 20),
            box(14, w: 120, r: 7),
            const SizedBox(height: 10),
            box(108, r: 16),
            const SizedBox(height: 20),
            box(14, w: 145, r: 7),
            const SizedBox(height: 10),
            box(54, r: 14),
            const SizedBox(height: 5),
            box(54, r: 14),
          ],
        );
      },
    );
  }
}

String _firstDisplayName(String companyName) {
  final cleaned = companyName.trim();
  if (cleaned.isEmpty) return 'there';
  final first = cleaned.split(RegExp(r'\s+')).first;
  if (first.isEmpty) return 'there';
  return '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
}


String _buildCompanyMeta(Map<String, dynamic>? profile, String statusValue) {
  final parts = <String>[];

  String? firstNonEmpty(List<String> keys) {
    for (final key in keys) {
      final value = profile?[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  final city = firstNonEmpty(['city', 'company_city']);
  final country = firstNonEmpty(['country', 'company_country']);
  final phone = firstNonEmpty(['phone', 'company_phone', 'mobile']);
  final email = firstNonEmpty(['email', 'company_email']);

  if (city != null) parts.add(city);
  if (country != null && country != city) parts.add(country);
  if (parts.isEmpty && phone != null) parts.add(phone);
  if (parts.isEmpty && email != null) parts.add(email);
  if (parts.isEmpty && statusValue.isNotEmpty) {
    parts.add('${statusValue[0].toUpperCase()}${statusValue.substring(1)} account');
  }
  if (parts.isEmpty) parts.add('Company account');

  return parts.take(2).join(' · ');
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
