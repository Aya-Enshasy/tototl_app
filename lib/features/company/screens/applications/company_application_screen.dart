import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_job_controller.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_job_posting_model.dart';
import '../../models/company_contract_model.dart';
import '../../services/company_job_service.dart';
import '../../services/company_contract_service.dart';
import '../contract/company_contract_detail_screen.dart';
import 'company_applicant_detail_screen.dart';
import 'company_applicant_list_item.dart';

class CompanyApplicationsScreen extends StatefulWidget {
  const CompanyApplicationsScreen({super.key});

  @override
  State<CompanyApplicationsScreen> createState() =>
      _CompanyApplicationsScreenState();
}

/// Backward-compatible wrapper so the current CompanyShellScreen keeps working
/// even before its import/widget name is changed from Operations to Applications.
class CompanyOperationsScreen extends StatelessWidget {
  const CompanyOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const CompanyApplicationsScreen();
}

class _CompanyApplicationsScreenState extends State<CompanyApplicationsScreen>
    with WidgetsBindingObserver {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_all_applications_v3_';
  static const int _perPage = 50;

  late final CompanyJobController _controller;
  late final CompanyContractController _contractController;

  Timer? _liveRefreshTimer;

  final List<CompanyApplicantListItem> _items = <CompanyApplicantListItem>[];

  String _companyName = 'Company';
  String _companyPhotoUrl = '';

  String? _selectedStatus;
  String? _errorMessage;
  String _sectionMode = 'applications';
  String _viewMode = 'all';
  String _contractFilter = 'all';
  String _searchQuery = '';
  bool _searchOpen = false;

  bool _cacheReadFinished = false;
  bool _hasSnapshot = false;
  bool _firstNetworkAttemptFinished = false;
  bool _networkRefreshing = false;
  bool _contractsRefreshing = false;
  bool _contractsRefreshQueued = false;

  int _viewSerial = 0;
  String? _queuedStatus;
  int? _queuedSerial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final apiClient = ApiClient();
    _controller = CompanyJobController(
      CompanyJobService(apiClient),
    );
    _contractController = CompanyContractController(
      CompanyContractService(apiClient),
    );

    unawaited(_loadCompanyIdentity());
    unawaited(_loadStatus(null));
    _startLiveRefresh();
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 12),
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
    if (!TickerMode.of(context)) return false;

    return true;
  }

  Future<void> _refreshLiveData() async {
    if (!_canAutoRefresh) return;

    final serial = _viewSerial;
    final status = _selectedStatus;

    await _refreshFromNetwork(
      status: status,
      serial: serial,
    );

    if (!mounted || serial != _viewSerial) return;
    await _refreshContracts();
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

  Future<void> _loadCompanyIdentity() async {
    final profile = await UserSessionStorage.getProfile();
    final storedPhoto = await UserSessionStorage.getProfilePhotoUrl();

    if (!mounted) return;

    final name =
    profile?['company_name']?.toString().trim().isNotEmpty == true
        ? profile!['company_name'].toString().trim()
        : (profile?['name']?.toString().trim().isNotEmpty == true
        ? profile!['name'].toString().trim()
        : 'Company');

    final directPhoto = profile?['profile_photo']?.toString().trim() ?? '';
    final alternatePhoto =
        profile?['profile_photo_url']?.toString().trim() ?? '';

    setState(() {
      _companyName = name;
      _companyPhotoUrl = directPhoto.isNotEmpty
          ? directPhoto
          : (alternatePhoto.isNotEmpty
          ? alternatePhoto
          : (storedPhoto?.trim() ?? ''));
    });
  }

  Future<void> _refreshContracts() async {
    if (_contractsRefreshing) {
      _contractsRefreshQueued = true;
      return;
    }

    _contractsRefreshing = true;
    if (mounted) setState(() {});

    try {
      await _contractController.loadContracts();
    } finally {
      _contractsRefreshing = false;

      final rerun = _contractsRefreshQueued;
      _contractsRefreshQueued = false;

      if (mounted) setState(() {});

      if (rerun && mounted) {
        unawaited(_refreshContracts());
      }
    }
  }

  Future<String> _resolveCacheKey(String? status) async {
    final userId = await UserSessionStorage.getUserId();
    final owner = userId?.toString().trim().isNotEmpty == true
        ? userId.toString().trim()
        : 'company';
    final bucket = status?.trim().toLowerCase().isNotEmpty == true
        ? status!.trim().toLowerCase()
        : 'all';
    return '$_cachePrefix${owner}_$bucket';
  }

  Future<void> _loadStatus(String? status) async {
    final normalized = _normalizeStatus(status);
    final serial = ++_viewSerial;

    if (mounted) {
      setState(() {
        _selectedStatus = normalized;
        _items.clear();
        _errorMessage = null;
        _cacheReadFinished = false;
        _hasSnapshot = false;
        _firstNetworkAttemptFinished = false;
      });
    }

    await _loadCache(normalized, serial);
    if (!mounted || serial != _viewSerial) return;

    unawaited(
      _refreshFromNetwork(
        status: normalized,
        serial: serial,
      ),
    );
  }

  Future<void> _loadCache(String? status, int serial) async {
    try {
      final key = await _resolveCacheKey(status);
      if (!mounted || serial != _viewSerial) return;
      final raw = await _storage.read(key: key);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      final values = decoded is Map ? decoded['items'] : decoded;
      if (values is! List) return;

      final cached = <CompanyApplicantListItem>[];
      for (final value in values) {
        if (value is Map) {
          cached.add(
            CompanyApplicantListItem.fromJson(
              Map<String, dynamic>.from(value),
            ),
          );
        }
      }

      _sortNewestFirst(cached);

      if (!mounted || serial != _viewSerial) return;
      setState(() {
        _items
          ..clear()
          ..addAll(cached);
        // An empty cached list is still a valid snapshot.
        _hasSnapshot = true;
      });
      if (cached.isNotEmpty) {
        unawaited(_refreshContracts());
      }
    } catch (_) {
      // Old/malformed cache must never block the live API request.
    } finally {
      if (mounted && serial == _viewSerial) {
        setState(() => _cacheReadFinished = true);
      }
    }
  }

  Future<void> _saveCache({
    required String? status,
    required List<CompanyApplicantListItem> items,
  }) async {
    try {
      final key = await _resolveCacheKey(status);
      await _storage.write(
        key: key,
        value: jsonEncode({
          'version': 3,
          'saved_at': DateTime.now().toIso8601String(),
          'status': status,
          'items': items.map((item) => item.toJson()).toList(growable: false),
        }),
      );
    } catch (_) {
      // Cache write failure should be invisible to the user.
    }
  }

  Future<void> _refreshFromNetwork({
    required String? status,
    required int serial,
    bool manual = false,
  }) async {
    if (_networkRefreshing) {
      _queuedStatus = status;
      _queuedSerial = serial;
      return;
    }

    _networkRefreshing = true;
    if (mounted && serial == _viewSerial) {
      setState(() {
        if (!_hasSnapshot) _errorMessage = null;
      });
    }

    try {
      final success = await _controller.loadCompanyApplicants(
        status: status,
        perPage: _perPage,
      );

      if (!mounted) return;

      // Do not paint a response that belongs to an old filter selection.
      if (serial != _viewSerial || status != _selectedStatus) return;

      if (success) {
        final fresh = List<CompanyApplicantListItem>.from(
          _controller.companyApplicants,
        );
        _sortNewestFirst(fresh);

        setState(() {
          _items
            ..clear()
            ..addAll(fresh);
          _hasSnapshot = true;
          _errorMessage = null;
        });

        unawaited(
          _saveCache(
            status: status,
            items: fresh,
          ),
        );
        await _refreshContracts();
      } else {
        final message = _controller.companyApplicantsErrorMessage ??
            'Unable to load applications.';

        if (!_hasSnapshot) {
          setState(() => _errorMessage = message);
        } else if (manual) {
          _showSnack(message, isError: true);
        }
      }
    } catch (e) {
      if (!mounted || serial != _viewSerial || status != _selectedStatus) {
        return;
      }

      if (!_hasSnapshot) {
        setState(() => _errorMessage = e.toString());
      } else if (manual) {
        _showSnack(e.toString(), isError: true);
      }
    } finally {
      _networkRefreshing = false;

      if (mounted && serial == _viewSerial) {
        setState(() => _firstNetworkAttemptFinished = true);
      }

      final queuedSerial = _queuedSerial;
      final queuedStatus = _queuedStatus;
      _queuedSerial = null;
      _queuedStatus = null;

      if (mounted &&
          queuedSerial != null &&
          queuedSerial == _viewSerial &&
          queuedStatus == _selectedStatus) {
        unawaited(
          _refreshFromNetwork(
            status: queuedStatus,
            serial: queuedSerial,
          ),
        );
      }
    }
  }

  Future<void> _manualRefresh() async {
    final serial = _viewSerial;
    final status = _selectedStatus;

    await _refreshFromNetwork(
      status: status,
      serial: serial,
      manual: true,
    );

    await _refreshContracts();
  }

  Future<void> _openApplication(
      CompanyApplicantListItem item,
      ) async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyApplicantDetailScreen(
          // /company/applicants returns the real job_posting_id plus nested
          // pilot_profile and drone, so pass that application object directly.
          jobId: item.application.jobPostingId,
          application: item.application,
        ),
      ),
    );

    if (!mounted) return;

    unawaited(_manualRefresh());

    if (changed == true) {
      _showSnack('Application updated.');
    }
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _showInitialShimmer =>
      !_hasSnapshot &&
          !_firstNetworkAttemptFinished &&
          (_items.isEmpty || !_cacheReadFinished);

  int get _pendingApplicationCount => _items
      .where(
        (item) =>
    item.application.status.trim().toLowerCase() == 'pending',
  )
      .length;

  List<CompanyApplicantListItem> get _visibleItems {
    Iterable<CompanyApplicantListItem> values = _items;

    if (_viewMode == 'review') {
      values = values.where(
            (item) =>
        item.application.status.trim().toLowerCase() == 'pending',
      );
    } else if (_viewMode == 'accepted') {
      values = values.where(
            (item) =>
        item.application.status.trim().toLowerCase() == 'accepted',
      );
    }

    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      values = values.where((item) {
        final application = item.application;
        final job = item.jobPosting;
        final pilot = application.pilotProfile;
        final drone = application.drone;

        final haystack = <String>[
          job?.title ?? '',
          job?.serviceCategory ?? '',
          job == null ? '' : _jobLocation(job),
          pilot?.displayName ?? '',
          pilot?.location ?? '',
          drone?.displayName ?? '',
          application.statusLabel,
          ...(drone?.capabilities ?? const <String>[]),
        ].join(' ').toLowerCase();

        return haystack.contains(query);
      });
    }

    final list = values.toList(growable: false);
    _sortNewestFirst(list);
    return list;
  }

  CompanyApplicantListItem? _applicationItemForContract(
      CompanyContractModel contract,
      ) {
    for (final item in _items) {
      if (contract.jobApplicationId > 0 &&
          item.application.id == contract.jobApplicationId) {
        return item;
      }
    }

    for (final item in _items) {
      if (item.application.jobPostingId == contract.jobPostingId &&
          item.application.pilotProfileId == contract.pilotProfileId) {
        return item;
      }
    }

    return null;
  }

  bool _contractNeedsAction(CompanyContractModel contract) {
    final status = contract.normalizedStatus.trim().toLowerCase();
    return status == 'accepted' || status == 'submitted';
  }

  bool _contractIsOngoing(CompanyContractModel contract) {
    final status = contract.normalizedStatus.trim().toLowerCase();
    return status == 'pending' ||
        status == 'active' ||
        status == 'in_progress';
  }

  int get _contractsNeedingAction =>
      _contractController.contracts.where(_contractNeedsAction).length;

  List<CompanyContractModel> get _visibleContracts {
    Iterable<CompanyContractModel> values =
        _contractController.contracts;

    switch (_contractFilter) {
      case 'action':
        values = values.where(_contractNeedsAction);
        break;
      case 'ongoing':
        values = values.where(_contractIsOngoing);
        break;
      case 'completed':
        values = values.where(
              (contract) =>
          contract.normalizedStatus.trim().toLowerCase() ==
              'completed',
        );
        break;
    }

    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      values = values.where((contract) {
        final item = _applicationItemForContract(contract);
        final job = item?.jobPosting;
        final pilot = item?.application.pilotProfile;
        final drone = item?.application.drone;

        final haystack = <String>[
          job?.title ?? '',
          job == null ? '' : _jobLocation(job),
          pilot?.displayName ?? '',
          pilot?.location ?? '',
          drone?.displayName ?? '',
          contract.statusLabel,
          contract.amountLabel,
          contract.paymentTypeLabel,
        ].join(' ').toLowerCase();

        return haystack.contains(query);
      });
    }

    final list = values.toList(growable: false);

    list.sort((a, b) {
      final ad =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _ApplicationsPalette.background,
        body: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(),
        _primarySectionTabs(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !_searchOpen
              ? const SizedBox.shrink(
            key: ValueKey('search-closed'),
          )
              : Padding(
            key: const ValueKey('search-open'),
            padding: const EdgeInsets.fromLTRB(20, 9, 20, 2),
            child: TextField(
              autofocus: true,
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
              style: const TextStyle(
                color: _ApplicationsPalette.navy,
                fontSize: 12.5,
              ),
              decoration: InputDecoration(
                hintText: _sectionMode == 'applications'
                    ? 'Search applications...'
                    : 'Search contracts...',
                hintStyle: const TextStyle(
                  color: _ApplicationsPalette.muted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _ApplicationsPalette.muted,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _ApplicationsPalette.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _ApplicationsPalette.teal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _sectionMode == 'applications'
                ? _buildApplicationsTab()
                : _buildContractsTab(),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    final applicationsSelected =
        _sectionMode == 'applications';
    final count = applicationsSelected
        ? _items.length
        : _contractController.contracts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Applications',
                  style: TextStyle(
                    color: _ApplicationsPalette.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  applicationsSelected
                      ? '$count application${count == 1 ? '' : 's'}'
                      : '$count contract${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _ApplicationsPalette.muted,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _searchQuery = '';
                });
              },
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _ApplicationsPalette.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ApplicationsPalette.navy
                          .withOpacity(.025),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _searchOpen
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: _ApplicationsPalette.navy,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primarySectionTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PrimarySectionTab(
                label: 'Applications',
                icon: Icons.assignment_outlined,
                selected:
                _sectionMode == 'applications',
                count: _pendingApplicationCount > 0
                    ? _pendingApplicationCount
                    : null,
                alert: _pendingApplicationCount > 0,
                onTap: () {
                  if (_sectionMode == 'applications') return;

                  HapticFeedback.selectionClick();
                  setState(() {
                    _sectionMode = 'applications';
                    _searchQuery = '';
                  });
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _PrimarySectionTab(
                label: 'Contracts',
                icon: Icons.description_outlined,
                selected: _sectionMode == 'contracts',
                count: _contractsNeedingAction > 0
                    ? _contractsNeedingAction
                    : null,
                alert: _contractsNeedingAction > 0,
                onTap: () {
                  if (_sectionMode == 'contracts') return;

                  HapticFeedback.selectionClick();

                  setState(() {
                    _sectionMode = 'contracts';
                    _searchQuery = '';
                  });

                  if (_contractController.contracts.isEmpty &&
                      !_contractsRefreshing) {
                    unawaited(_refreshContracts());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTab() {
    final visible = _visibleItems;
    final grouped =
    <int, List<CompanyApplicantListItem>>{};

    for (final item in visible) {
      final id = item.application.jobPostingId;
      grouped
          .putIfAbsent(
        id,
            () => <CompanyApplicantListItem>[],
      )
          .add(item);
    }

    final groups = grouped.entries.toList(growable: false)
      ..sort((a, b) {
        final ad =
            a.value.first.application.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            b.value.first.application.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);

        return bd.compareTo(ad);
      });

    if (_showInitialShimmer) {
      return const _ApplicationsPageShimmer();
    }

    if (_errorMessage != null && !_hasSnapshot) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: () =>
            _loadStatus(_selectedStatus),
      );
    }

    return Column(
      key: const ValueKey('applications-tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _applicationFilters(),
        if (_viewMode == 'review' &&
            _pendingApplicationCount > 0) ...[
          const SizedBox(height: 11),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            child: _ReviewAlertStrip(
              submissionCount: 0,
              applicationCount:
              _pendingApplicationCount,
            ),
          ),
        ],
        const SizedBox(height: 11),
        Expanded(
          child: RefreshIndicator(
            color: _ApplicationsPalette.teal,
            backgroundColor: Colors.white,
            onRefresh: _manualRefresh,
            child: visible.isEmpty
                ? _ReferenceEmptyApplications(
              mode: _viewMode,
            )
                : ListView.builder(
              physics:
              const AlwaysScrollableScrollPhysics(
                parent:
                BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                92,
              ),
              itemCount: groups.length,
              itemBuilder: (_, index) {
                final items =
                    groups[index].value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index == groups.length - 1
                        ? 0
                        : 18,
                  ),
                  child: _JobApplicationsGroup(
                    items: items,
                    companyName: _companyName,
                    companyPhotoUrl:
                    _companyPhotoUrl,
                    onOpen: _openApplication,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _applicationFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: _ReferenceFilterButton(
              label: 'All',
              selected: _viewMode == 'all',
              onTap: () {
                if (_viewMode == 'all') return;
                HapticFeedback.selectionClick();
                setState(() => _viewMode = 'all');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 11,
            child: _ReferenceFilterButton(
              label: 'To review',
              selected: _viewMode == 'review',
              badge: _pendingApplicationCount > 0
                  ? _pendingApplicationCount
                  : null,
              onTap: () {
                if (_viewMode == 'review') return;
                HapticFeedback.selectionClick();
                setState(() => _viewMode = 'review');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _ReferenceFilterButton(
              label: 'Accepted',
              selected: _viewMode == 'accepted',
              onTap: () {
                if (_viewMode == 'accepted') return;
                HapticFeedback.selectionClick();
                setState(() => _viewMode = 'accepted');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab() {
    final contracts = _visibleContracts;

    if (_contractsRefreshing &&
        _contractController.contracts.isEmpty) {
      return const _ContractsTabShimmer(
        key: ValueKey('contracts-loading'),
      );
    }

    if (_contractController.errorMessage != null &&
        _contractController.contracts.isEmpty) {
      return _ErrorView(
        message: _contractController.errorMessage!,
        onRetry: _refreshContracts,
      );
    }

    return Column(
      key: const ValueKey('contracts-tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _contractFilters(),
        const SizedBox(height: 11),
        Expanded(
          child: RefreshIndicator(
            color: _ApplicationsPalette.teal,
            backgroundColor: Colors.white,
            onRefresh: _refreshContracts,
            child: contracts.isEmpty
                ? _ReferenceEmptyContracts(
              filter: _contractFilter,
            )
                : ListView.separated(
              physics:
              const AlwaysScrollableScrollPhysics(
                parent:
                BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                92,
              ),
              itemCount: contracts.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 11),
              itemBuilder: (_, index) {
                final contract =
                contracts[index];

                final applicationItem =
                _applicationItemForContract(
                  contract,
                );

                return _ReferenceContractCard(
                  contract: contract,
                  applicationItem:
                  applicationItem,
                  onTap: () =>
                      _openContractFromContracts(
                        contract,
                        applicationItem,
                      ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _contractFilters() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _CompactContractFilter(
            label: 'All',
            selected: _contractFilter == 'all',
            onTap: () => setState(
                  () => _contractFilter = 'all',
            ),
          ),
          const SizedBox(width: 8),
          _CompactContractFilter(
            label: 'Needs action',
            selected: _contractFilter == 'action',
            badge: _contractsNeedingAction > 0
                ? _contractsNeedingAction
                : null,
            onTap: () => setState(
                  () => _contractFilter = 'action',
            ),
          ),
          const SizedBox(width: 8),
          _CompactContractFilter(
            label: 'Ongoing',
            selected: _contractFilter == 'ongoing',
            onTap: () => setState(
                  () => _contractFilter = 'ongoing',
            ),
          ),
          const SizedBox(width: 8),
          _CompactContractFilter(
            label: 'Completed',
            selected:
            _contractFilter == 'completed',
            onTap: () => setState(
                  () => _contractFilter = 'completed',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openContractFromContracts(
      CompanyContractModel contract,
      CompanyApplicantListItem? applicationItem,
      ) async {
    HapticFeedback.selectionClick();

    final changed =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyContractDetailScreen(
          contractId: contract.id,
          initialContract: contract,
          initialJob: applicationItem?.jobPosting,
          initialApplication:
          applicationItem?.application,
        ),
      ),
    );

    if (!mounted) return;

    await _refreshContracts();

    if (changed == true) {
      _showSnack('Contract updated.');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : AppColors.navy,
          content: Text(
            message,
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
      );
  }
}

class _JobApplicationsGroup extends StatelessWidget {
  const _JobApplicationsGroup({
    required this.items,
    required this.companyName,
    required this.companyPhotoUrl,
    required this.onOpen,
  });

  final List<CompanyApplicantListItem> items;
  final String companyName;
  final String companyPhotoUrl;
  final Future<void> Function(CompanyApplicantListItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final first = items.first;
    final job = first.jobPosting;

    final title = job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Job';

    final location = job == null ? '' : _jobLocation(job);

    final jobCompanyName = _readDynamicCompanyName(job?.companyProfile);
    final jobCompanyPhoto = _readDynamicCompanyImage(job?.companyProfile);

    final resolvedCompanyName =
    jobCompanyName.isNotEmpty ? jobCompanyName : companyName;
    final resolvedCompanyPhoto =
    jobCompanyPhoto.isNotEmpty ? jobCompanyPhoto : companyPhotoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ApplicationsPalette.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.15,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _ApplicationsPalette.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ApplicationsPalette.muted,
                              fontSize: 10.7,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${items.length} application${items.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _ApplicationsPalette.muted,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ...items.map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReferenceApplicationCard(
              item: item,
              companyName: resolvedCompanyName,
              companyPhotoUrl: resolvedCompanyPhoto,
              onTap: () => onOpen(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceApplicationCard extends StatelessWidget {
  const _ReferenceApplicationCard({
    required this.item,
    required this.companyName,
    required this.companyPhotoUrl,
    required this.onTap,
  });

  final CompanyApplicantListItem item;
  final String companyName;
  final String companyPhotoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final application = item.application;
    final job = item.jobPosting;
    final pilot = application.pilotProfile;
    final drone = application.drone;

    final applicationStatus =
    application.status.trim().toLowerCase();

    final pilotName =
    pilot?.displayName.trim().isNotEmpty == true
        ? pilot!.displayName.trim()
        : 'Pilot';

    final pilotPhoto = pilot?.profilePhoto.trim() ?? '';
    final experience = pilot?.experienceYears;
    final pilotLocation = pilot?.location.trim() ?? '';

    final jobTitle = job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Job';

    final jobLocation =
    job == null ? '' : _jobLocation(job);

    final droneName =
    drone?.displayName.trim().isNotEmpty == true
        ? drone!.displayName.trim()
        : 'Selected drone';

    final droneImage = drone?.imageUrl.trim() ?? '';

    final capabilities =
        drone?.capabilities ?? const <String>[];

    final capabilityText = capabilities.isEmpty
        ? ''
        : capabilities.take(2).map(_pretty).join(', ');

    final payment =
    job == null ? '—' : _payment(job);

    final paymentType =
    job == null ? '' : _pretty(job.paymentType);

    final visual = _statusVisual(application.status);

    final actionLabel = switch (applicationStatus) {
      'pending' => 'View proposal',
      'accepted' => 'View application',
      'rejected' => 'View details',
      'withdrawn' => 'View details',
      _ => 'Open application',
    };

    final bottomTitle = switch (applicationStatus) {
      'pending' => 'Awaiting your decision',
      'accepted' => 'Pilot accepted for this job',
      'rejected' => 'Application rejected',
      'withdrawn' => 'Application withdrawn',
      _ => application.statusLabel,
    };

    final bottomSubtitle =
    _formatDateTime(application.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding:
          const EdgeInsets.fromLTRB(13, 12, 13, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _ApplicationsPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: _ApplicationsPalette.navy
                    .withOpacity(.022),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ReferenceStatusBadge(
                    label:
                    application.statusLabel.trim().isEmpty
                        ? _pretty(application.status)
                        : application.statusLabel.trim(),
                    foreground: visual.foreground,
                    background: visual.background,
                  ),
                  const Spacer(),
                  Text(
                    applicationStatus == 'pending'
                        ? 'New application'
                        : _pretty(application.status),
                    style: const TextStyle(
                      color:
                      _ApplicationsPalette.muted,
                      fontSize: 9.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  _ReferenceCompanySquare(
                    name: companyName,
                    imageUrl: companyPhotoUrl,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            _ApplicationsPalette.navy,
                            fontSize: 12.8,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        if (jobLocation.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons
                                    .location_on_outlined,
                                size: 13,
                                color:
                                _ApplicationsPalette
                                    .tealDark,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  jobLocation,
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    color:
                                    _ApplicationsPalette
                                        .text,
                                    fontSize: 10.4,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  _ReferencePilotAvatar(
                    url: pilotPhoto,
                    name: pilotName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          pilotName,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            _ApplicationsPalette.navy,
                            fontSize: 12.1,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (experience != null)
                              '$experience years experience',
                            if (pilotLocation.isNotEmpty)
                              pilotLocation,
                          ].join(' · '),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            _ApplicationsPalette.muted,
                            fontSize: 10.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CompactDetail(
                      imageUrl: droneImage,
                      icon: Icons.flight_outlined,
                      title: droneName,
                      subtitle: capabilityText.isEmpty
                          ? 'Drone'
                          : capabilityText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactDetail(
                      icon:
                      Icons.payments_outlined,
                      title: payment,
                      subtitle: paymentType,
                      accent:
                      _ApplicationsPalette.tealDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color:
                    _ApplicationsPalette.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          bottomTitle,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            _ApplicationsPalette.navy,
                            fontSize: 10.9,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        if (bottomSubtitle
                            .trim()
                            .isNotEmpty)
                          Text(
                            bottomSubtitle,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                              _ApplicationsPalette
                                  .muted,
                              fontSize: 9.9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ReferenceActionButton(
                    label: actionLabel,
                    compact: true,
                    onTap: onTap,
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

class _CompactDetail extends StatelessWidget {
  const _CompactDetail({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.imageUrl = '',
    this.accent = _ApplicationsPalette.navy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _ApplicationsPalette.tealSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: imageUrl.trim().isNotEmpty
              ? Image.network(
            imageUrl.trim(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              icon,
              size: 17,
              color: _ApplicationsPalette.tealDark,
            ),
          )
              : Icon(
            icon,
            size: 17,
            color: _ApplicationsPalette.tealDark,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 10.9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ApplicationsPalette.muted,
                    fontSize: 9.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}



class _PrimarySectionTab extends StatelessWidget {
  const _PrimarySectionTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
    this.alert = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          padding:
          const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
              BoxShadow(
                color: _ApplicationsPalette.navy
                    .withOpacity(.055),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? _ApplicationsPalette.tealDark
                    : _ApplicationsPalette.muted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _ApplicationsPalette.navy
                        : _ApplicationsPalette.muted,
                    fontSize: 11.1,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                _LiveCountBadge(
                  count: count!,
                  backgroundColor: alert
                      ? _ApplicationsPalette.orange
                      : _ApplicationsPalette.tealSoft,
                  foregroundColor: alert
                      ? Colors.white
                      : _ApplicationsPalette.tealDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactContractFilter extends StatelessWidget {
  const _CompactContractFilter({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          padding: EdgeInsets.only(
            left: 13,
            right: badge == null ? 13 : 8,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [
                Color(0xFF13B3C2),
                Color(0xFF0B98B3),
              ],
            )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0C9FB6)
                  : _ApplicationsPalette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : _ApplicationsPalette.navy,
                  fontSize: 10.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                _LiveCountBadge(
                  count: badge!,
                  backgroundColor: selected
                      ? const Color(0xFFF06446)
                      : _ApplicationsPalette.orangeSoft,
                  foregroundColor: selected
                      ? Colors.white
                      : _ApplicationsPalette.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceContractCard extends StatelessWidget {
  const _ReferenceContractCard({
    required this.contract,
    required this.applicationItem,
    required this.onTap,
  });

  final CompanyContractModel contract;
  final CompanyApplicantListItem? applicationItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final job = applicationItem?.jobPosting;
    final application = applicationItem?.application;
    final pilot = application?.pilotProfile;
    final drone = application?.drone;

    final title =
    job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Mission';

    final location =
    job == null ? '' : _jobLocation(job);

    final pilotName =
    pilot?.displayName.trim().isNotEmpty == true
        ? pilot!.displayName.trim()
        : 'Pilot';

    final pilotPhoto =
        pilot?.profilePhoto.trim() ?? '';

    final droneName =
    drone?.displayName.trim().isNotEmpty == true
        ? drone!.displayName.trim()
        : 'Selected drone';

    final status =
    contract.normalizedStatus.trim().toLowerCase();

    final visual = _contractVisual(status);

    final needsAction =
        status == 'accepted' || status == 'submitted';

    final actionLabel = switch (status) {
      'pending' => 'View contract',
      'accepted' => 'Fund contract',
      'active' => 'Open mission',
      'in_progress' => 'Open mission',
      'submitted' => 'Review work',
      'completed' => 'View completed',
      _ => 'View details',
    };

    final stateText = switch (status) {
      'pending' => 'Waiting for pilot decision',
      'accepted' => 'Pilot accepted · funding required',
      'active' => 'Funded · ready for work',
      'in_progress' => 'Work in progress',
      'submitted' => 'Work submitted · review required',
      'completed' => 'Mission completed',
      'cancelled' => 'Contract cancelled',
      'terminated' => 'Contract terminated',
      'rejected' => 'Contract rejected',
      _ => contract.statusLabel,
    };

    final showProgress = const {
      'pending',
      'accepted',
      'active',
      'in_progress',
      'submitted',
      'completed',
    }.contains(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding:
          const EdgeInsets.fromLTRB(13, 12, 13, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: needsAction
                  ? visual.foreground.withOpacity(.28)
                  : _ApplicationsPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: _ApplicationsPalette.navy
                    .withOpacity(.024),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _ReferencePilotAvatar(
                    url: pilotPhoto,
                    name: pilotName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color:
                                  _ApplicationsPalette.navy,
                                  fontSize: 12.9,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            _ReferenceStatusBadge(
                              label:
                              contract.statusLabel,
                              foreground:
                              visual.foreground,
                              background:
                              visual.background,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pilotName,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                            _ApplicationsPalette.text,
                            fontSize: 10.7,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .location_on_outlined,
                                size: 12.5,
                                color:
                                _ApplicationsPalette
                                    .muted,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    color:
                                    _ApplicationsPalette
                                        .muted,
                                    fontSize: 9.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _ContractMetricTile(
                      icon: Icons.flight_outlined,
                      label: 'Drone',
                      value: droneName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContractMetricTile(
                      icon:
                      Icons.payments_outlined,
                      label: 'Agreement',
                      value:
                      '${contract.amountLabel} · ${contract.paymentTypeLabel}',
                      accent: _ApplicationsPalette
                          .tealDark,
                    ),
                  ),
                ],
              ),
              if (showProgress) ...[
                const SizedBox(height: 13),
                _MissionProgressStrip(
                  status: status,
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  10,
                  9,
                  8,
                  9,
                ),
                decoration: BoxDecoration(
                  color: needsAction
                      ? visual.background.withOpacity(.85)
                      : const Color(0xFFF8FAFB),
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      needsAction
                          ? Icons
                          .notifications_active_outlined
                          : Icons.schedule_rounded,
                      size: 15,
                      color: needsAction
                          ? visual.foreground
                          : _ApplicationsPalette.muted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        stateText,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          _ApplicationsPalette.navy,
                          fontSize: 10.3,
                          fontWeight: needsAction
                              ? FontWeight.w700
                              : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ReferenceActionButton(
                      label: actionLabel,
                      compact: true,
                      onTap: onTap,
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

class _ContractMetricTile extends StatelessWidget {
  const _ContractMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = _ApplicationsPalette.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE6ECEF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: _ApplicationsPalette.tealSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color:
              _ApplicationsPalette.tealDark,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:
                    _ApplicationsPalette.muted,
                    fontSize: 8.9,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.2,
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

class _ContractsTabShimmer extends StatelessWidget {
  const _ContractsTabShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        20,
        38,
        20,
        92,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 11),
      itemBuilder: (_, __) => Container(
        height: 205,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: _ApplicationsPalette.border,
          ),
        ),
      ),
    );
  }
}

class _ReferenceEmptyContracts extends StatelessWidget {
  const _ReferenceEmptyContracts({
    required this.filter,
  });

  final String filter;

  @override
  Widget build(BuildContext context) {
    final (title, text) = switch (filter) {
      'action' => (
      'Nothing needs your action',
      'Funding and review tasks will appear here.'
      ),
      'ongoing' => (
      'No ongoing contracts',
      'Active work and contracts waiting on the pilot will appear here.'
      ),
      'completed' => (
      'No completed contracts yet',
      'Finished missions will stay available here.'
      ),
      _ => (
      'No contracts yet',
      'Contracts appear here after you create one from an accepted application.'
      ),
    };

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(28, 80, 28, 120),
      children: [
        Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
              _ApplicationsPalette.tealSoft,
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 28,
              color:
              _ApplicationsPalette.tealDark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ApplicationsPalette.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ApplicationsPalette.muted,
            fontSize: 10.7,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

_VisualPair _contractVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        Color(0xFF0A8D74),
        Color(0xFFE8F8F3),
      );
    case 'active':
    case 'in_progress':
      return const _VisualPair(
        Color(0xFF0B91A8),
        Color(0xFFE7F7F9),
      );
    case 'submitted':
      return const _VisualPair(
        Color(0xFFE47C2A),
        Color(0xFFFFF0E3),
      );
    case 'completed':
      return const _VisualPair(
        Color(0xFF0A8D74),
        Color(0xFFE8F8F3),
      );
    case 'cancelled':
    case 'terminated':
    case 'rejected':
      return const _VisualPair(
        Color(0xFFD9574F),
        Color(0xFFFFECEA),
      );
    default:
      return const _VisualPair(
        Color(0xFFB7791F),
        Color(0xFFFFF5E6),
      );
  }
}

class _ApplicationsPalette {
  static const background = Color(0xFFF9FCFD);
  static const navy = Color(0xFF0A2D46);
  static const text = Color(0xFF566B7C);
  static const muted = Color(0xFF7E90A0);
  static const teal = Color(0xFF12AEC0);
  static const tealDark = Color(0xFF0B97AE);
  static const tealSoft = Color(0xFFE9F9F8);
  static const border = Color(0xFFDCE8EC);
  static const orange = Color(0xFFF07A2C);
  static const orangeSoft = Color(0xFFFFF1E8);
  static const green = Color(0xFF10A889);
  static const greenSoft = Color(0xFFE8FAF5);
}

class _ReferenceFilterButton extends StatelessWidget {
  const _ReferenceFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: [
                  Color(0xFF11AFC0),
                  Color(0xFF0B98B4),
                ],
              )
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0B98B4)
                    : _ApplicationsPalette.border,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: _ApplicationsPalette.teal.withOpacity(.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                      selected ? Colors.white : _ApplicationsPalette.navy,
                      fontSize: 10.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  _LiveCountBadge(
                    count: badge!,
                    backgroundColor: selected
                        ? const Color(0xFFF06446)
                        : _ApplicationsPalette.orangeSoft,
                    foregroundColor: selected
                        ? Colors.white
                        : _ApplicationsPalette.orange,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCountBadge extends StatelessWidget {
  const _LiveCountBadge({
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final int count;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final singleDigit = count >= 0 && count < 10;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      width: singleDigit ? 20 : null,
      height: 20,
      constraints: BoxConstraints(
        minWidth: singleDigit ? 20 : 24,
      ),
      padding: singleDigit
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: singleDigit ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: singleDigit ? null : BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 8.8,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReviewAlertStrip extends StatelessWidget {
  const _ReviewAlertStrip({
    required this.submissionCount,
    required this.applicationCount,
  });

  final int submissionCount;
  final int applicationCount;

  @override
  Widget build(BuildContext context) {
    final hasSubmission = submissionCount > 0;
    final count = hasSubmission ? submissionCount : applicationCount;
    final label = hasSubmission
        ? '$count submission${count == 1 ? '' : 's'} awaiting review'
        : '$count new application${count == 1 ? '' : 's'} to review';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _ApplicationsPalette.orangeSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.watch_later_outlined,
            color: _ApplicationsPalette.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _ApplicationsPalette.orange,
                fontSize: 11.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _ApplicationsPalette.orange,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ReferenceStatusBadge extends StatelessWidget {
  const _ReferenceStatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReferenceJobThumb extends StatelessWidget {
  const _ReferenceJobThumb({
    required this.imageUrl,
    required this.category,
  });

  final String imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 78,
        height: 56,
        color: const Color(0xFFE9F1F3),
        child: imageUrl.trim().isNotEmpty
            ? Image.network(
          imageUrl.trim(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ReferenceJobThumbFallback(
            category: category,
          ),
        )
            : _ReferenceJobThumbFallback(category: category),
      ),
    );
  }
}

class _ReferenceJobThumbFallback extends StatelessWidget {
  const _ReferenceJobThumbFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8BC2C8), Color(0xFF3A7583)],
        ),
      ),
      child: const Icon(
        Icons.landscape_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _ReferenceCompanySquare extends StatelessWidget {
  const _ReferenceCompanySquare({
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F4),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _ApplicationsPalette.border,
          width: .8,
        ),
      ),
      child: imageUrl.trim().isNotEmpty
          ? Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) =>
            _ReferenceCompanySquareFallback(name: name),
      )
          : _ReferenceCompanySquareFallback(name: name),
    );
  }
}

class _ReferenceCompanySquareFallback extends StatelessWidget {
  const _ReferenceCompanySquareFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8CCAD2),
            Color(0xFF4B8998),
          ],
        ),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReferencePilotAvatar extends StatelessWidget {
  const _ReferencePilotAvatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEAF2F4),
      ),
      child: ClipOval(
        child: url.trim().isNotEmpty
            ? Image.network(
          url.trim(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PilotAvatarFallback(
            initials: _initials(name),
          ),
        )
            : _PilotAvatarFallback(initials: _initials(name)),
      ),
    );
  }
}

class _ReferenceInfoCell extends StatelessWidget {
  const _ReferenceInfoCell({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = _ApplicationsPalette.navy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          height: 34,
          child: Icon(
            icon,
            color: accent == _ApplicationsPalette.teal
                ? _ApplicationsPalette.teal
                : _ApplicationsPalette.navy,
            size: 22,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 11.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ApplicationsPalette.text,
                    fontSize: 10,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferenceCompanyAvatar extends StatelessWidget {
  const _ReferenceCompanyAvatar({
    required this.name,
    required this.url,
    this.size = 44,
  });

  final String name;
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF3F5),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _ApplicationsPalette.navy.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: url.trim().isEmpty
            ? Center(
          child: Text(
            _initials(name),
            style: TextStyle(
              color: _ApplicationsPalette.tealDark,
              fontSize: size <= 34 ? 9.5 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
            : Image.network(
          url.trim(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              _initials(name),
              style: TextStyle(
                color: _ApplicationsPalette.tealDark,
                fontSize: size <= 34 ? 9.5 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractStatePill extends StatelessWidget {
  const _ContractStatePill({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color foreground = _ApplicationsPalette.tealDark;
    Color background = _ApplicationsPalette.tealSoft;

    if (status == 'submitted') {
      foreground = _ApplicationsPalette.orange;
      background = _ApplicationsPalette.orangeSoft;
    } else if (status == 'completed') {
      foreground = _ApplicationsPalette.green;
      background = _ApplicationsPalette.greenSoft;
    } else if (status == 'pending') {
      foreground = _ApplicationsPalette.orange;
      background = _ApplicationsPalette.orangeSoft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MissionProgressStrip extends StatelessWidget {
  const _MissionProgressStrip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'Contract\nsigned',
      'Funded',
      'Working',
      'Review',
      'Paid',
    ];

    final normalized = status.trim().toLowerCase();

    int current;
    int completedThrough;
    bool allCompleted = false;

    switch (normalized) {
      case 'pending':
        current = 0;
        completedThrough = -1;
        break;

      case 'accepted':
        current = 1;
        completedThrough = 0;
        break;

      case 'active':
      case 'in_progress':
        current = 2;
        completedThrough = 1;
        break;

      case 'submitted':
        current = 3;
        completedThrough = 2;
        break;

      case 'completed':
        current = 4;
        completedThrough = 4;
        allCompleted = true;
        break;

      default:
        current = 0;
        completedThrough = -1;
    }

    return Column(
      children: [
        Row(
          children: List.generate(labels.length * 2 - 1, (index) {
            if (index.isOdd) {
              final leftStep = index ~/ 2;
              final activeLine =
                  allCompleted || leftStep < completedThrough;

              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: activeLine
                        ? _ApplicationsPalette.teal
                        : const Color(0xFFD8E3E8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }

            final step = index ~/ 2;
            final completed = allCompleted || step <= completedThrough;
            final isCurrent = !allCompleted && step == current;

            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                completed ? _ApplicationsPalette.teal : Colors.white,
                border: Border.all(
                  color: completed || isCurrent
                      ? _ApplicationsPalette.tealDark
                      : const Color(0xFFC8D4DA),
                  width: isCurrent && !completed ? 2 : 1.4,
                ),
              ),
              child: completed
                  ? const Icon(
                Icons.check_rounded,
                size: 12,
                color: Colors.white,
              )
                  : isCurrent
                  ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _ApplicationsPalette.tealDark,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          children: List.generate(labels.length, (index) {
            final emphasized =
                allCompleted || index <= completedThrough || index == current;

            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: emphasized
                      ? _ApplicationsPalette.navy
                      : _ApplicationsPalette.muted,
                  fontSize: 8.5,
                  fontWeight:
                  emphasized ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ReferenceActionButton extends StatelessWidget {
  const _ReferenceActionButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 13 : 17,
            vertical: compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF17B6C5),
                Color(0xFF0797B5),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0AA4BA).withOpacity(.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceEmptyApplications extends StatelessWidget {
  const _ReferenceEmptyApplications({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final title = mode == 'review'
        ? 'Nothing to review'
        : mode == 'accepted'
        ? 'No accepted applications'
        : 'No applications yet';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _ApplicationsPalette.tealSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: _ApplicationsPalette.teal,
              size: 29,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ApplicationsPalette.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.pending,
  });

  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withOpacity(0.08),
            AppColors.logoTurquoiseDark.withOpacity(0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppColors.blue,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$total total application${total == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.orangeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pending pending',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.icon,
    required this.text,
    this.accent = AppColors.blue,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.065),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent == AppColors.green ? AppColors.green : AppColors.navy,
                fontSize: 10.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.blue,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.blue : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.navy,
        fontSize: 11.3,
        fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    );
  }
}


class _PilotAvatarFallback extends StatelessWidget {
  const _PilotAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: AppColors.blueBg,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyPulse(),
          SizedBox(width: 6),
          Text(AppLanguage.text('Updating'),
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'No applications yet'
        : 'No ${_pretty(status!)} applications';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 31,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(AppLanguage.text('Applications from pilots will appear here as soon as they apply to your jobs.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.7,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(AppLanguage.text('Could not load applications'),
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.7,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(AppLanguage.text('Try Again'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsBackground extends StatelessWidget {
  const _ApplicationsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -155,
          right: -125,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 430,
          left: -190,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoiseDark.withOpacity(0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PREMIUM SHIMMER
// =============================================================================

class _ApplicationsPageShimmer extends StatelessWidget {
  const _ApplicationsPageShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 108, height: 16, radius: 7),
                      SizedBox(height: 8),
                      _ShimmerBox(width: 158, height: 9, radius: 5),
                    ],
                  ),
                ),
                _ShimmerBox(width: 72, height: 27, radius: 14),
              ],
            ),
            SizedBox(height: 18),
            _ShimmerBox(height: 50, radius: 16),
            SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  _ShimmerBox(width: 55, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 76, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 82, height: 31, radius: 16),
                  SizedBox(width: 8),
                  _ShimmerBox(width: 78, height: 31, radius: 16),
                ],
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _ApplicationCardSkeleton(),
                    SizedBox(height: 11),
                    _ApplicationCardSkeleton(),
                    SizedBox(height: 11),
                    _ApplicationCardSkeleton(),
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

class _ApplicationCardSkeleton extends StatelessWidget {
  const _ApplicationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 42, height: 42, radius: 13),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 158, height: 13, radius: 6),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 112, height: 9, radius: 5),
                  ],
                ),
              ),
              _ShimmerBox(width: 64, height: 24, radius: 12),
            ],
          ),
          SizedBox(height: 13),
          _PilotSkeleton(),
          SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 38, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: _ShimmerBox(height: 38, radius: 12)),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBox(width: 175, height: 9, radius: 5),
        ],
      ),
    );
  }
}

class _PilotSkeleton extends StatelessWidget {
  const _PilotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          _ShimmerBox(width: 42, height: 42, radius: 21),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 120, height: 11, radius: 5),
                SizedBox(height: 7),
                _ShimmerBox(width: 165, height: 8, radius: 4),
              ],
            ),
          ),
          _ShimmerBox(width: 18, height: 18, radius: 9),
        ],
      ),
    );
  }
}

class _ShimmerAnimator extends StatefulWidget {
  const _ShimmerAnimator({required this.child});

  final Widget child;

  @override
  State<_ShimmerAnimator> createState() => _ShimmerAnimatorState();
}

class _ShimmerAnimatorState extends State<_ShimmerAnimator>
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
      child: widget.child,
      builder: (context, child) {
        final x = -1.5 + (_controller.value * 3.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
              Colors.white,
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
            stops: const [0.0, 0.30, 0.50, 0.70, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TinyPulse extends StatefulWidget {
  const _TinyPulse();

  @override
  State<_TinyPulse> createState() => _TinyPulseState();
}

class _TinyPulseState extends State<_TinyPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.45,
      upperBound: 1,
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
      opacity: _controller,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VisualPair {
  const _VisualPair(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

_VisualPair _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'withdrawn':
      return _VisualPair(AppColors.grey, Colors.grey.shade100);
    default:
      return const _VisualPair(AppColors.orange, AppColors.orangeBg);
  }
}

String? _normalizeStatus(String? value) {
  final clean = value?.trim().toLowerCase() ?? '';
  return clean.isEmpty ? null : clean;
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';

  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
    '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
  )
      .join(' ');
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _jobLocation(CompanyJobPostingModel job) {
  final parts = <String>[
    if (job.city.trim().isNotEmpty) job.city.trim(),
    if (job.state.trim().isNotEmpty) job.state.trim(),
    if (job.country.trim().isNotEmpty) job.country.trim(),
  ];

  if (parts.isEmpty && job.region.trim().isNotEmpty) {
    return job.region.trim();
  }

  return parts.join(', ');
}

String _readDynamicJobImage(dynamic job) {
  String clean(dynamic value) => value?.toString().trim() ?? '';
  try {
    final value = clean(job.coverImageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.coverImage);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.imageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.image);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = clean(job.thumbnailUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final attachments = job.attachments;
    if (attachments is Iterable) {
      for (final item in attachments) {
        try {
          if (item.isImage != true) continue;
        } catch (_) {}
        try {
          final value = clean(item.url);
          if (value.isNotEmpty) return value;
        } catch (_) {}
        try {
          final value = clean(item.fileUrl);
          if (value.isNotEmpty) return value;
        } catch (_) {}
      }
    }
  } catch (_) {}
  return '';
}

String _payment(CompanyJobPostingModel job) {
  final type = job.paymentType.trim().toLowerCase();
  if (type == 'negotiable') return 'Negotiable';

  final min = _money(job.paymentMin);
  final max = _money(job.paymentMax);
  final label = _pretty(type);

  if (job.paymentMin == null && job.paymentMax == null) {
    return label.isEmpty ? 'Payment —' : label;
  }

  if (job.paymentMax == null || job.paymentMax == job.paymentMin) {
    return label.isEmpty ? '\$$min' : '\$$min · $label';
  }

  return '\$$min–\$$max${label.isEmpty ? '' : ' · $label'}';
}

String _money(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '${local.year}-$month-$day · $hour:$minute';
}

String _readDynamicDroneImage(dynamic drone) {
  // GET /v1/company/applicants currently returns the committed drone specs
  // (make/model/capabilities/etc.) but does not return a drone image URL.
  //
  // Never fall back to generic `photo`, `photoUrl` or `image` fields here:
  // those can belong to the pilot/profile and can cause the pilot photo to
  // appear as the drone image.
  if (drone == null) return '';

  try {
    return drone.imageUrl?.toString().trim() ?? '';
  } catch (_) {
    return '';
  }
}

String _readDynamicCompanyName(dynamic company) {
  String clean(dynamic value) => value?.toString().trim() ?? '';

  if (company == null) return '';

  try {
    final value = clean(company.companyName);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final value = clean(company.name);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  return '';
}

String _readDynamicCompanyImage(dynamic company) {
  String clean(dynamic value) => value?.toString().trim() ?? '';

  if (company == null) return '';

  try {
    final value = clean(company.profilePhoto);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final value = clean(company.profilePhotoUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final value = clean(company.logoUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final value = clean(company.logo);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  try {
    final value = clean(company.imageUrl);
    if (value.isNotEmpty) return value;
  } catch (_) {}

  return '';
}

void _sortNewestFirst(List<CompanyApplicantListItem> values) {
  values.sort((a, b) {
    final left = a.application.createdAt;
    final right = b.application.createdAt;

    if (left == null && right == null) {
      return b.application.id.compareTo(a.application.id);
    }
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
}
