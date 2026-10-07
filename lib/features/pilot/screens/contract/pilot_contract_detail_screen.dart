import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../company/models/contract_submission_model.dart';
import '../../controllers/pilot_contract_controller.dart';
 import '../../models/pilot_contract_model.dart';
import '../../models/pilot_contract_location_model.dart';
 import '../../services/pilot_contract_service.dart';
import 'pilot_submit_work_screen.dart';

class PilotContractDetailScreen extends StatefulWidget {
  const PilotContractDetailScreen({
    super.key,
    required this.contractId,
    this.initialContract,
  });

  final int contractId;
  final PilotContractModel? initialContract;

  @override
  State<PilotContractDetailScreen> createState() =>
      _PilotContractDetailScreenState();
}

class _PilotContractDetailScreenState
    extends State<PilotContractDetailScreen>
    with WidgetsBindingObserver {
  late final PilotContractController _controller;
  late final PilotContractController _locationWatcherController;

  PilotContractModel? _contract;
  PilotContractLocationModel? _location;
  List<ContractSubmissionModel> _submissions = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _changed = false;

  Timer? _liveRefreshTimer;
  Timer? _locationWatchTimer;

  bool _liveSyncInFlight = false;
  bool _locationWatchInFlight = false;

  String? _error;

  bool get _acting =>
      _controller.isAccepting ||
      _controller.isRejecting ||
      _controller.isStartingWork ||
      _controller.isSubmittingWork;

  @override
  void initState() {
    super.initState();

    _controller = PilotContractController(
      PilotContractService(ApiClient()),
    );

    // Dedicated controller for Exact Location polling. It is intentionally
    // separate from the main contract controller so a contract/submission
    // request can never block the location watcher.
    _locationWatcherController = PilotContractController(
      PilotContractService(ApiClient()),
    );

    _contract = widget.initialContract;
    _loading = _contract == null;

    WidgetsBinding.instance.addObserver(this);

    unawaited(
      _load(initial: true).whenComplete(() {
        if (mounted) {
          unawaited(_syncExactLocation(force: true));
        }
      }),
    );

    _startLiveRefresh();
    _startLocationWatcher();
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();

    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_syncLiveWorkflow()),
    );
  }

  void _startLocationWatcher() {
    _locationWatchTimer?.cancel();

    // Exact Location is time-sensitive for the Pilot because Start Work is
    // blocked until it exists. Poll it independently and more frequently than
    // the rest of the workflow.
    _locationWatchTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_syncExactLocation()),
    );
  }

  Future<void> _syncExactLocation({
    bool force = false,
  }) async {
    if (!mounted || _locationWatchInFlight) return;

    final contract = _contract;
    if (contract == null) return;

    if (!contract.canViewExactLocation) {
      if (_location != null && mounted) {
        setState(() => _location = null);
      }
      return;
    }

    // Once a location is present we do not need aggressive polling anymore.
    // The normal workflow sync still refreshes it later if needed.
    if (!force && _location != null) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!force && lifecycle != AppLifecycleState.resumed) return;

    _locationWatchInFlight = true;

    try {
      final freshLocation =
          await _locationWatcherController.loadLocation(contract.id);

      if (!mounted || freshLocation == null) return;

      setState(() {
        _location = freshLocation;
        _changed = true;
      });

      // The dependency is resolved. Stop the high-frequency watcher.
      _locationWatchTimer?.cancel();
      _locationWatchTimer = null;
    } finally {
      _locationWatchInFlight = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncLiveWorkflow(force: true));
      unawaited(_syncExactLocation(force: true));

      if (_location == null && _locationWatchTimer == null) {
        _startLocationWatcher();
      }
    }
  }

  Future<void> _syncLiveWorkflow({
    bool force = false,
  }) async {
    if (!mounted || _liveSyncInFlight) return;

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!force && lifecycle != AppLifecycleState.resumed) return;

    if (_acting || _refreshing || _loading) return;

    _liveSyncInFlight = true;

    try {
      final previousStatus =
          _contract?.normalizedStatus.trim().toLowerCase();

      final freshContract =
          await _controller.loadContract(widget.contractId);

      if (!mounted || freshContract == null) return;

      PilotContractLocationModel? freshLocation = _location;

      if (freshContract.canViewExactLocation) {
        final loadedLocation = await _controller.loadLocation(
          freshContract.id,
        );

        // Never erase a confirmed location because one transient refresh
        // returned null. If it is not loaded yet, the dedicated watcher keeps
        // checking independently every two seconds.
        if (loadedLocation != null) {
          freshLocation = loadedLocation;
        }
      } else {
        freshLocation = null;
      }

      List<ContractSubmissionModel> freshSubmissions = _submissions;
      if (freshContract.isInProgress ||
          freshContract.isSubmitted ||
          freshContract.isCompleted) {
        freshSubmissions = await _controller.loadSubmissions(
          freshContract.id,
        );
      } else {
        freshSubmissions = const <ContractSubmissionModel>[];
      }

      if (!mounted) return;

      final nextStatus =
          freshContract.normalizedStatus.trim().toLowerCase();

      setState(() {
        _contract = freshContract;
        _location = freshLocation;
        _submissions = List<ContractSubmissionModel>.unmodifiable(
          freshSubmissions,
        );

        if (previousStatus != null && previousStatus != nextStatus) {
          _changed = true;
        }
      });

      if (freshContract.canViewExactLocation &&
          _location == null &&
          _locationWatchTimer == null) {
        _startLocationWatcher();
        unawaited(_syncExactLocation(force: true));
      }
    } finally {
      _liveSyncInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveRefreshTimer?.cancel();
    _locationWatchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({
    bool initial = false,
  }) async {
    final hasData = _contract != null;

    if (mounted) {
      setState(() {
        if (!hasData) {
          _loading = true;
        } else if (!initial) {
          _refreshing = true;
        }
        _error = null;
      });
    }

    final loadedContract = await _controller.loadContract(widget.contractId);
    final resolvedContract = loadedContract ?? _contract;

    PilotContractLocationModel? resolvedLocation = _location;

    if (resolvedContract != null &&
        resolvedContract.canViewExactLocation) {
      final loadedLocation =
          await _controller.loadLocation(resolvedContract.id);

      if (loadedLocation != null) {
        resolvedLocation = loadedLocation;
      }
    } else {
      resolvedLocation = null;
    }

    var resolvedSubmissions = _submissions;
    if (resolvedContract != null &&
        (resolvedContract.isInProgress ||
            resolvedContract.isSubmitted ||
            resolvedContract.isCompleted)) {
      resolvedSubmissions = await _controller.loadSubmissions(resolvedContract.id);
    } else if (resolvedContract != null && resolvedContract.isActive) {
      resolvedSubmissions = const [];
    }

    if (!mounted) return;

    setState(() {
      if (loadedContract != null) {
        _contract = loadedContract;
      } else if (!hasData) {
        _error = _controller.detailErrorMessage;
      }
      _location = resolvedLocation;
      _submissions = List.unmodifiable(resolvedSubmissions);
      _loading = false;
      _refreshing = false;
    });

    if (resolvedContract != null &&
        resolvedContract.canViewExactLocation &&
        _location == null) {
      if (_locationWatchTimer == null) {
        _startLocationWatcher();
      }
      unawaited(_syncExactLocation(force: true));
    }
  }

  Future<void> _startWork() async {
    final contract = _contract;
    if (contract == null ||
        !contract.canStartWork ||
        _location == null ||
        _acting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.flight_takeoff_rounded, color: AppColors.blue),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Start Work?',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Confirm that you are ready to begin this mission at the exact contract location. The contract will move from Active to In Progress and the start time will be recorded.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
              child: const Text('Start Work'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.startWork(contract.id);
    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to start work.',
      );
      return;
    }

    final optimistic = updated.isInProgress
        ? updated
        : updated.copyWith(
            status: 'in_progress',
            startedAt: updated.startedAt ?? DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

    // Update the UI immediately so Start Work can never remain visible after a
    // successful action. Then reconcile from GET /contracts/{id}.
    setState(() {
      _contract = optimistic;
      _changed = true;
    });

    final fresh = await _controller.loadContract(contract.id);
    if (mounted && fresh != null && fresh.isInProgress) {
      setState(() => _contract = fresh);
    }

    _snack(
      'Work started. Contract is now In Progress.',
      success: true,
    );

    unawaited(_syncLiveWorkflow(force: true));
  }

  Future<void> _openSubmitWork() async {
    final contract = _contract;
    if (contract == null || !contract.canSubmitWork || _acting) return;

    ContractSubmissionModel? latest;
    if (_submissions.isNotEmpty) latest = _submissions.last;

    HapticFeedback.selectionClick();
    final result = await Navigator.of(context).push<PilotSubmitWorkResult>(
      MaterialPageRoute(
        builder: (_) => PilotSubmitWorkScreen(
          contractId: contract.id,
          previousSubmission:
              latest?.isRevisionRequested == true ? latest : null,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final optimistic = result.contract.isSubmitted
        ? result.contract
        : result.contract.copyWith(
            status: 'submitted',
            submittedAt: result.contract.submittedAt ?? DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

    final list = List<ContractSubmissionModel>.from(_submissions);
    final index = list.indexWhere((item) => item.id == result.submission.id);
    if (index == -1) {
      list.add(result.submission);
    } else {
      list[index] = result.submission;
    }

    setState(() {
      _contract = optimistic;
      _submissions = List.unmodifiable(list);
      _changed = true;
    });

    final fresh = await _controller.loadContract(contract.id);
    if (mounted && fresh != null && fresh.isSubmitted) {
      setState(() => _contract = fresh);
    }

    _snack('Work submitted. Waiting for company review.', success: true);
    unawaited(_syncLiveWorkflow(force: true));
  }

  Future<void> _accept() async {
    final contract = _contract;
    if (contract == null || !contract.canPilotDecide || _acting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            AppLanguage.text('Accept Contract?'),
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            AppLanguage.text(
              'By accepting, you agree to the contract terms. The company will then need to fund the contract before work can begin.',
            ),
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLanguage.text('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              child: Text(AppLanguage.text('Accept Contract')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.acceptContract(contract.id);

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ??
            'Unable to accept this contract.',
      );
      return;
    }

    setState(() {
      _contract = updated;
      _changed = true;
    });

    _snack(
      'Contract accepted. Waiting for company funding.',
      success: true,
    );
    unawaited(_syncLiveWorkflow(force: true));
  }

  Future<void> _reject() async {
    final contract = _contract;
    if (contract == null || !contract.canPilotDecide || _acting) return;

    String reason = '';

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            AppLanguage.text('Reject Contract?'),
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLanguage.text(
                  'You may add a reason for the company. This is optional.',
                ),
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                onChanged: (value) => reason = value,
                decoration: InputDecoration(
                  hintText: AppLanguage.text(
                    'Optional rejection reason...',
                  ),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLanguage.text('Keep Contract')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                reason.trim(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
              ),
              child: Text(AppLanguage.text('Reject Contract')),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.rejectContract(
      contract.id,
      reason: result.isEmpty ? null : result,
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ??
            'Unable to reject this contract.',
      );
      return;
    }

    setState(() {
      _contract = updated;
      _changed = true;
    });

    _snack('Contract rejected.', success: true);
  }

  void _back() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const _ContractBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: _loading && _contract == null
                        ? const _DetailShimmer()
                        : _error != null && _contract == null
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
        bottomNavigationBar: _bottomActions(),
      ),
    );
  }

  Widget _topBar() {
    final contract = _contract;
    final status = contract?.statusLabel ?? 'Loading';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
      child: Row(
        children: [
          _PremiumRoundButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _back,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Mission Contract'),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17.2,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF13B8A6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$status · Live workflow',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _LiveSyncPill(
            active: _liveSyncInFlight || _locationWatchInFlight,
          ),
        ],
      ),
    );
  }


  Widget _content() {
    final contract = _contract!;
    final visual = _statusVisual(contract.status);

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
        children: [
          _hero(contract, visual),
          const SizedBox(height: 12),
          _PremiumWorkflowTracker(
            contract: contract,
            hasLocation: _location != null,
          ),
          const SizedBox(height: 12),
          _statusMessage(contract),
          const SizedBox(height: 12),
          _overview(contract),
          const SizedBox(height: 12),
          _schedule(contract),
          if (contract.canViewExactLocation) ...[
            const SizedBox(height: 12),
            _locationSection(contract),
          ],
          if (contract.isInProgress ||
              contract.isSubmitted ||
              contract.isCompleted) ...[
            const SizedBox(height: 12),
            _workSubmissionSection(contract),
          ],
          const SizedBox(height: 12),
          _terms(contract),
          const SizedBox(height: 12),
          _references(contract),
          if (contract.createdAt != null ||
              contract.updatedAt != null) ...[
            const SizedBox(height: 12),
            _audit(contract),
          ],
        ],
      ),
    );
  }

  Widget _hero(
    PilotContractModel contract,
    _ContractVisual visual,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061728),
            Color(0xFF07394C),
            Color(0xFF087D88),
          ],
          stops: [0.0, .58, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087E91).withOpacity(.17),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -44,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(.07),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -46,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4FE2D1).withOpacity(.055),
              ),
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
                      color: Colors.white.withOpacity(.09),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(.10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.white.withOpacity(.82),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CONTRACT #${contract.id}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.82),
                            fontSize: 8.4,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(
                    label: contract.statusLabel,
                    foreground: visual.foreground,
                    background: visual.background,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                contract.amountLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${contract.paymentTypeLabel} agreement',
                style: TextStyle(
                  color: Colors.white.withOpacity(.64),
                  fontSize: 10.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroInfoChip(
                      icon: Icons.calendar_month_outlined,
                      label: 'Schedule',
                      value: contract.dateRangeLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HeroInfoChip(
                      icon: Icons.assignment_outlined,
                      label: 'Application',
                      value: '#${contract.jobApplicationId}',
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


  Widget _statusMessage(PilotContractModel contract) {
    String title;
    String message;
    IconData icon;
    Color accent;
    Color background;

    switch (contract.status) {
      case 'pending':
        title = 'Your decision is required';
        message =
            'Review the amount, schedule and terms below. Accepting moves the contract to Accepted and the company must fund it before work can start.';
        icon = Icons.pending_actions_rounded;
        accent = AppColors.orange;
        background = AppColors.orangeBg;
        break;
      case 'accepted':
        title = 'Waiting for company funding';
        message =
            'You accepted this contract. Work cannot start until the company funds it and the contract becomes Active.';
        icon = Icons.hourglass_top_rounded;
        accent = AppColors.blue;
        background = AppColors.blueBg;
        break;
      case 'active':
        title = _location == null
            ? 'Waiting for exact job location'
            : 'Ready to start work';
        message = _location == null
            ? 'Funding is confirmed. This screen is checking automatically and will unlock Start Work as soon as the company location becomes available.'
            : 'The exact location is available. Review it below, then use Start Work when you are ready.';
        icon = _location == null
            ? Icons.location_off_outlined
            : Icons.flight_takeoff_rounded;
        accent = _location == null ? AppColors.orange : AppColors.green;
        background = _location == null ? AppColors.orangeBg : AppColors.greenBg;
        break;
      case 'in_progress':
        final latest = _submissions.isEmpty ? null : _submissions.last;
        final revisionRequested = latest?.isRevisionRequested == true;
        title = revisionRequested ? 'Revision requested' : 'Work in progress';
        message = revisionRequested
            ? (latest!.reviewNotes.trim().isEmpty
                ? 'The company requested another submission. Review the latest round below and submit the corrected work.'
                : 'Company feedback: ${latest.reviewNotes}')
            : contract.startedAt == null
                ? 'This mission has started. Submit the completed work when it is ready.'
                : 'Work started at ${_formatDateTime(contract.startedAt)}. Submit the completed work when it is ready.';
        icon = revisionRequested ? Icons.replay_rounded : Icons.flight_rounded;
        accent = revisionRequested ? AppColors.orange : AppColors.blue;
        background = revisionRequested ? AppColors.orangeBg : AppColors.blueBg;
        break;
      case 'submitted':
        title = 'Work submitted';
        message = 'Your work has been submitted and is waiting for company review.';
        icon = Icons.task_alt_rounded;
        accent = AppColors.green;
        background = AppColors.greenBg;
        break;
      case 'rejected':
        title = 'Contract rejected';
        message =
            'This contract is closed because it was rejected by the pilot.';
        icon = Icons.cancel_outlined;
        accent = AppColors.red;
        background = AppColors.redBg;
        break;
      default:
        title = contract.statusLabel;
        message =
            'This contract has moved to the next workflow stage.';
        icon = Icons.info_outline_rounded;
        accent = AppColors.blue;
        background = AppColors.blueBg;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background.withOpacity(0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent.withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(title),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text(message),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 10.7,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(PilotContractModel contract) {
    return _section(
      icon: Icons.payments_outlined,
      title: 'Contract Value',
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Amount',
              value: contract.amountLabel,
              icon: Icons.account_balance_wallet_outlined,
              accent: AppColors.green,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _Metric(
              label: 'Payment Type',
              value: contract.paymentTypeLabel,
              icon: Icons.tune_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _schedule(PilotContractModel contract) {
    return _section(
      icon: Icons.calendar_month_outlined,
      title: 'Schedule',
      child: Column(
        children: [
          _infoRow(
            'Start date',
            _formatDate(contract.startDate),
            Icons.play_circle_outline_rounded,
          ),
          _infoRow(
            'End date',
            _formatDate(contract.endDate),
            Icons.event_available_outlined,
          ),
        ],
      ),
    );
  }

  Widget _workSubmissionSection(PilotContractModel contract) {
    final latest = _submissions.isEmpty ? null : _submissions.last;

    return _section(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Work Submission',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_controller.isLoadingSubmissions && latest == null)
            const Row(
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(width: 9),
                Text(
                  'Loading submission history...',
                  style: TextStyle(color: AppColors.grey, fontSize: 10.5),
                ),
              ],
            )
          else if (latest == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.blueBg.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No work has been submitted yet. When the mission is ready, use Submit Work below.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 10.8,
                  height: 1.45,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: latest.isRevisionRequested
                        ? AppColors.orangeBg
                        : latest.isApproved
                            ? AppColors.greenBg
                            : AppColors.blueBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    latest.statusLabel,
                    style: TextStyle(
                      color: latest.isRevisionRequested
                          ? AppColors.orange
                          : latest.isApproved
                              ? AppColors.green
                              : AppColors.blue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Round ${_submissions.length}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoLine('Submitted', latest.submittedLabel),
            _infoLine('Attachments', '${latest.files.length}'),
            if (latest.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                latest.notes,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 10.8,
                  height: 1.45,
                ),
              ),
            ],
            if (latest.reviewNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: latest.isRevisionRequested
                      ? AppColors.orangeBg.withOpacity(0.7)
                      : AppColors.greenBg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  latest.reviewNotes,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
          if (_controller.submissionErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _controller.submissionErrorMessage!,
              style: const TextStyle(color: AppColors.red, fontSize: 9.8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terms(PilotContractModel contract) {
    return _section(
      icon: Icons.gavel_outlined,
      title: 'Terms',
      child: Text(
        contract.terms.trim().isEmpty
            ? AppLanguage.text('No additional terms were provided.')
            : contract.terms.trim(),
        style: TextStyle(
          color: contract.terms.trim().isEmpty
              ? AppColors.grey
              : AppColors.text,
          fontSize: 11.8,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _locationSection(PilotContractModel contract) {
    final location = _location;

    return _section(
      icon: Icons.location_on_outlined,
      title: 'Exact Job Location',
      child: _controller.isLoadingLocation && location == null
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Loading protected location...',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            )
          : location == null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF8EC),
                        Color(0xFFFFFCF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_searching_rounded,
                          color: AppColors.orange,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waiting for Exact Location',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No action is needed from you. This screen checks the protected location automatically and unlocks Start Work the moment it becomes available.',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 10.4,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.7,
                                    color: AppColors.orange.withOpacity(.82),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'Live checking every 2 seconds',
                                  style: TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAFBF7), Color(0xFFF2F8FC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.green.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            color: AppColors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              location.address,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 12.2,
                                height: 1.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: SelectableText(
                              location.coordinatesLabel,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy coordinates',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: location.coordinatesLabel),
                              );
                              _snack('Coordinates copied.', success: true);
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                      if (location.notes.trim().isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.cardBorder),
                        Text(
                          location.notes.trim(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 10.8,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (contract.isActive) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(
                              Icons.lock_open_rounded,
                              color: AppColors.green,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Location access unlocked by the Active contract.',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _references(PilotContractModel contract) {
    return _section(
      icon: Icons.link_rounded,
      title: 'References',
      child: Column(
        children: [
          _infoRow(
            'Job',
            '#${contract.jobPostingId}',
            Icons.work_outline_rounded,
          ),
          _infoRow(
            'Application',
            '#${contract.jobApplicationId}',
            Icons.assignment_outlined,
          ),
          _infoRow(
            'Pilot profile',
            '#${contract.pilotProfileId}',
            Icons.person_outline_rounded,
          ),
          _infoRow(
            'Company profile',
            '#${contract.companyProfileId}',
            Icons.business_outlined,
          ),
        ],
      ),
    );
  }

  Widget _audit(PilotContractModel contract) {
    return _section(
      icon: Icons.history_rounded,
      title: 'Contract History',
      child: Column(
        children: [
          if (contract.createdAt != null)
            _infoRow(
              'Created',
              _formatDateTime(contract.createdAt),
              Icons.add_task_rounded,
            ),
          if (contract.updatedAt != null)
            _infoRow(
              'Last update',
              _formatDateTime(contract.updatedAt),
              Icons.update_rounded,
            ),
          if (contract.rejectedAt != null)
            _infoRow(
              'Rejected',
              _formatDateTime(contract.rejectedAt),
              Icons.cancel_outlined,
            ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                AppLanguage.text(title),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLanguage.text(label),
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _bottomActions() {
    final contract = _contract;

    if (_loading || contract == null) return null;

    if (contract.canPilotDecide) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.985),
            border: const Border(
              top: BorderSide(color: AppColors.cardBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 22,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: AppColors.red,
                    side: BorderSide(
                      color: AppColors.red.withOpacity(0.40),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    _controller.isRejecting
                        ? AppLanguage.text('Rejecting...')
                        : AppLanguage.text('Reject'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _acting ? null : _accept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _controller.isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    _controller.isAccepting
                        ? AppLanguage.text('Accepting...')
                        : AppLanguage.text('Accept Contract'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (contract.canStartWork) {
      final locationReady = _location != null;
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.985),
            border: const Border(
              top: BorderSide(color: AppColors.cardBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 22,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: !locationReady || _acting ? null : _startWork,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.lightGrey.withOpacity(0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _controller.isStartingWork
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    locationReady
                        ? Icons.flight_takeoff_rounded
                        : Icons.location_off_outlined,
                    size: 19,
                  ),
            label: Text(
              _controller.isStartingWork
                  ? 'Starting Work...'
                  : locationReady
                      ? 'Start Work'
                      : 'Waiting for Exact Location',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }

    if (contract.canSubmitWork) {
      final latest = _submissions.isEmpty ? null : _submissions.last;
      final isRevision = latest?.isRevisionRequested == true;
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.985),
            border: const Border(top: BorderSide(color: AppColors.cardBorder)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 22,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _acting ? null : _openSubmitWork,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: isRevision ? AppColors.orange : AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.cloud_upload_outlined, size: 19),
            label: Text(
              isRevision ? 'Submit Revised Work' : 'Submit Work',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      );
    }

    return null;
  }

  void _snack(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? AppColors.green : AppColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(message),
        ),
      );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
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
}


class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(.075),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: const Color(0xFF79E2D8).withOpacity(.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF83E7DF),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.45),
                    fontSize: 7.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.92),
                    fontSize: 8.8,
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

class _LiveSyncPill extends StatelessWidget {
  const _LiveSyncPill({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF11A99D).withOpacity(.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0B9A91),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF13B8A6),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            active ? 'Syncing' : 'Live',
            style: const TextStyle(
              color: Color(0xFF087F79),
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRoundButton extends StatelessWidget {
  const _PremiumRoundButton({
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
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
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

class _PremiumWorkflowTracker extends StatelessWidget {
  const _PremiumWorkflowTracker({
    required this.contract,
    required this.hasLocation,
  });

  final PilotContractModel contract;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'Agreement',
      'Fund',
      'Location',
      'Work',
      'Review',
      'Complete',
    ];

    final status = contract.normalizedStatus;

    int current;
    int completeThrough;

    if (status == 'pending') {
      current = 0;
      completeThrough = -1;
    } else if (status == 'accepted') {
      current = 1;
      completeThrough = 0;
    } else if (status == 'active' && !hasLocation) {
      current = 2;
      completeThrough = 1;
    } else if (status == 'active') {
      current = 3;
      completeThrough = 2;
    } else if (status == 'in_progress') {
      current = 3;
      completeThrough = 2;
    } else if (status == 'submitted') {
      current = 4;
      completeThrough = 3;
    } else if (status == 'completed') {
      current = 5;
      completeThrough = 5;
    } else {
      current = 0;
      completeThrough = -1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.022),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              labels.length * 2 - 1,
              (index) {
                if (index.isOdd) {
                  final segment = index ~/ 2;
                  final filled = segment < completeThrough;
                  return Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFF0CA49B)
                            : const Color(0xFFDCE5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }

                final step = index ~/ 2;
                final complete = step <= completeThrough;
                final active = step == current && !complete;

                return Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete
                        ? const Color(0xFF0CA49B)
                        : active
                            ? const Color(0xFFE8F8F6)
                            : Colors.white,
                    border: Border.all(
                      color: complete || active
                          ? const Color(0xFF0CA49B)
                          : const Color(0xFFC9D5DA),
                      width: active ? 2 : 1.2,
                    ),
                  ),
                  child: complete
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : active
                          ? const Center(
                              child: SizedBox(
                                width: 6,
                                height: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0CA49B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          : null,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: labels.asMap().entries.map((entry) {
              final index = entry.key;
              final emphasized =
                  index <= completeThrough || index == current;

              return Expanded(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: emphasized
                        ? AppColors.navy
                        : AppColors.lightGrey,
                    fontSize: 7.7,
                    fontWeight:
                        emphasized ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.blue,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 15),
          const SizedBox(height: 7),
          Text(
            AppLanguage.text(label),
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
        horizontal: 9,
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
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
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
        onTap: onTap,
        customBorder: const CircleBorder(),
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
              color: AppColors.orange,
              size: 34,
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

class _ContractBackdrop extends StatelessWidget {
  const _ContractBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
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
            Positioned(
              bottom: -140,
              left: -130,
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

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _Skeleton(height: 205, radius: 26),
        SizedBox(height: 12),
        _Skeleton(height: 82, radius: 17),
        SizedBox(height: 12),
        _Skeleton(height: 130, radius: 20),
        SizedBox(height: 12),
        _Skeleton(height: 135, radius: 20),
        SizedBox(height: 12),
        _Skeleton(height: 150, radius: 20),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.height,
    required this.radius,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

_ContractVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _ContractVisual(
        AppColors.blue,
        Color(0xFFDCEEFE),
      );
    case 'active':
    case 'in_progress':
    case 'completed':
      return const _ContractVisual(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'submitted':
      return const _ContractVisual(
        AppColors.orange,
        AppColors.orangeBg,
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
        AppColors.orange,
        AppColors.orangeBg,
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
