import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_contract_location_model.dart';
import '../../models/company_contract_model.dart';
 import '../../../payments/models/payment_model.dart';
import '../../../payments/screens/payment_history_screen.dart';
import '../../../payments/services/payment_service.dart';
import '../../models/contract_submission_model.dart';
import '../../services/company_contract_service.dart';
import 'company_contract_location_screen.dart';
import 'company_contracts_screen.dart';
import 'company_submission_review_screen.dart';

class CompanyContractDetailScreen extends StatefulWidget {
  const CompanyContractDetailScreen({
    super.key,
    required this.contractId,
    this.initialContract,
  });

  final int contractId;
  final CompanyContractModel? initialContract;

  @override
  State<CompanyContractDetailScreen> createState() =>
      _CompanyContractDetailScreenState();
}

class _CompanyContractDetailScreenState
    extends State<CompanyContractDetailScreen> {
  late final CompanyContractController _controller;

  CompanyContractModel? _contract;
  CompanyContractLocationModel? _location;
  List<ContractSubmissionModel> _submissions = const [];

  bool _initialLoading = true;
  bool _refreshing = false;
  bool _changed = false;
  String? _error;

  bool get _acting =>
      _controller.isFunding ||
      _controller.isLoadingLocation ||
      _controller.isSavingLocation ||
      _controller.isLoadingSubmissions ||
      _controller.isReviewingSubmission;

  @override
  void initState() {
    super.initState();
    _controller = CompanyContractController(
      CompanyContractService(ApiClient()),
    );
    _contract = widget.initialContract;
    if (_contract != null) {
      _controller.seed(_contract!);
      _initialLoading = false;
    }
    unawaited(_load(initial: true));
  }

  Future<void> _load({bool initial = false}) async {
    final hadData = _contract != null;

    if (mounted) {
      setState(() {
        if (!hadData) {
          _initialLoading = true;
        } else if (!initial) {
          _refreshing = true;
        }
        _error = null;
      });
    }

    final ok = await _controller.loadContract(widget.contractId);
    final freshContract = ok ? _controller.selectedContract : _contract;

    CompanyContractLocationModel? freshLocation = _location;
    if (freshContract != null && freshContract.shouldShowLocationSection) {
      final loadedLocation = await _controller.loadLocation(freshContract.id);
      if (loadedLocation != null || _controller.locationErrorMessage == null) {
        freshLocation = loadedLocation;
      }
      // On a transient location lookup error, keep any already-known saved
      // location instead of turning the UI back into "Add Location".
    }

    var freshSubmissions = _submissions;
    if (freshContract != null &&
        (freshContract.isInProgress ||
            freshContract.isSubmitted ||
            freshContract.isCompleted)) {
      freshSubmissions = await _controller.loadSubmissions(freshContract.id);
    }

    if (!mounted) return;

    setState(() {
      if (freshContract != null) {
        _contract = freshContract;
      } else if (!hadData) {
        _error = _controller.errorMessage ?? 'Unable to load this contract.';
      }
      _location = freshLocation;
      _submissions = List.unmodifiable(freshSubmissions);
      _initialLoading = false;
      _refreshing = false;
    });
  }

  Future<void> _fund() async {
    final contract = _contract;
    if (contract == null || !contract.canFund || _controller.isFunding) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.green,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Fund Contract',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Confirm funding ${contract.amountLabel}. The current backend payment gateway is a stub, so this request has no card/body fields. On success the contract becomes Active.',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12.2,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Fund Contract'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.fundContract(contract.id);
    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to fund this contract.',
        error: true,
      );
      return;
    }

    CompanyContractLocationModel? location;
    if (updated.shouldShowLocationSection) {
      location = await _controller.loadLocation(updated.id);
    }

    if (!mounted) return;

    setState(() {
      _contract = updated;
      _location = location;
      _changed = true;
    });

    _snack(
      'Funding confirmed. Contract is Active. Add the exact job location next.',
      success: true,
    );
  }

  Future<void> _openLocationEditor() async {
    final contract = _contract;
    if (contract == null || !contract.canConfigureLocation || _acting) return;

    HapticFeedback.selectionClick();

    final saved = await Navigator.of(context)
        .push<CompanyContractLocationModel>(
      MaterialPageRoute(
        builder: (_) => CompanyContractLocationScreen(
          contractId: contract.id,
          initialLocation: _location,
        ),
      ),
    );

    if (!mounted || saved == null) return;

    setState(() {
      _location = saved;
      _changed = true;
    });

    _snack(
      'Exact location saved. The pilot can now access it from the active contract.',
      success: true,
    );
  }

  Future<void> _openPaymentHistory() async {
    final contract = _contract;
    if (contract == null) return;

    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentHistoryScreen(
          audience: PaymentAudience.company,
          contractId: contract.id,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _openLatestSubmission() async {
    final contract = _contract;
    if (contract == null || _submissions.isEmpty || _acting) return;

    final latest = _submissions.last;
    HapticFeedback.selectionClick();
    final result = await Navigator.of(context).push<CompanySubmissionReviewResult>(
      MaterialPageRoute(
        builder: (_) => CompanySubmissionReviewScreen(
          contractId: contract.id,
          submission: latest,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final list = List<ContractSubmissionModel>.from(_submissions);
    final index = list.indexWhere((item) => item.id == result.submission.id);
    if (index == -1) {
      list.add(result.submission);
    } else {
      list[index] = result.submission;
    }

    setState(() {
      _contract = result.contract;
      _submissions = List.unmodifiable(list);
      _changed = true;
    });

    // Reconcile from the server after every workflow action. Review endpoints
    // return a submission object, while contract state changes separately.
    await _load();
  }

  void _back() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    final contract = _contract;

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
                    child: _initialLoading && contract == null
                        ? const _DetailLoading()
                        : _error != null && contract == null
                            ? _ErrorState(
                                message: _error!,
                                onRetry: () => _load(),
                              )
                            : _content(contract!),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: contract?.canFund == true
            ? _fundBar(contract!)
            : contract?.canReviewSubmission == true && _submissions.isNotEmpty
                ? _reviewBar(contract!)
                : null,
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _back,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contract Details',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Funding, location & work lifecycle',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_refreshing)
            const SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue,
                  ),
                ),
              ),
            )
          else
            _CircleButton(
              icon: Icons.refresh_rounded,
              onTap: _acting ? null : () => _load(),
            ),
        ],
      ),
    );
  }

  Widget _content(CompanyContractModel contract) {
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
        children: [
          _hero(contract),
          const SizedBox(height: 12),
          _statusCard(contract),
          const SizedBox(height: 12),
          _section(
            title: 'Contract Snapshot',
            icon: Icons.description_outlined,
            child: Column(
              children: [
                _infoRow('Job', '#${contract.jobPostingId}'),
                _infoRow('Application', '#${contract.jobApplicationId}'),
                _infoRow('Pilot', '#${contract.pilotProfileId}'),
                _infoRow('Start', _date(contract.startDate)),
                if (contract.endDate != null)
                  _infoRow('End', _date(contract.endDate)),
                _infoRow('Payment Type', contract.paymentTypeLabel),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Lifecycle',
            icon: Icons.route_rounded,
            child: _timeline(contract),
          ),
          if (contract.shouldShowLocationSection) ...[
            const SizedBox(height: 12),
            _locationSection(contract),
          ],
          if (contract.isInProgress ||
              contract.isSubmitted ||
              contract.isCompleted) ...[
            const SizedBox(height: 12),
            _submissionSection(contract),
          ],
          if (contract.terms.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              title: 'Terms',
              icon: Icons.gavel_outlined,
              child: Text(
                contract.terms,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _section(
            title: 'Payment',
            icon: Icons.account_balance_wallet_outlined,
            child: _payment(contract),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CompanyContractsScreen(),
              ),
            ),
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('All Contracts'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(CompanyContractModel contract) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D39),
            Color(0xFF0B4357),
            Color(0xFF0D8799),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  contract.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${contract.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            contract.amountLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${contract.paymentTypeLabel} payment • Job #${contract.jobPostingId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (contract.isActive) ...[
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF7BE4D8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _location == null
                          ? 'Funding confirmed. Add the exact job location so the pilot can start work.'
                          : 'Funding and exact location are ready. The pilot can start work.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.8,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
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

  Widget _statusCard(CompanyContractModel contract) {
    String title;
    String message;
    IconData icon;
    Color color;
    Color background;

    if (contract.isPending) {
      title = 'Waiting for pilot decision';
      message = 'The pilot must accept the contract before company funding.';
      icon = Icons.hourglass_top_rounded;
      color = AppColors.orange;
      background = AppColors.orangeBg;
    } else if (contract.isAccepted) {
      title = 'Ready for funding';
      message = 'The pilot accepted. Fund the contract to activate the work stage.';
      icon = Icons.account_balance_wallet_rounded;
      color = AppColors.green;
      background = AppColors.greenBg;
    } else if (contract.isActive) {
      title = _location == null
          ? 'Active • Location required'
          : 'Active • Ready for pilot';
      message = _location == null
          ? 'Funding is complete. Add the private exact location before the pilot starts work.'
          : 'The pilot can see the exact location and use Start Work.';
      icon = Icons.location_on_rounded;
      color = AppColors.blue;
      background = AppColors.blueBg;
    } else if (contract.isInProgress) {
      final latest = _submissions.isEmpty ? null : _submissions.last;
      final revisionRequested = latest?.isRevisionRequested == true;
      title = revisionRequested ? 'Revision requested' : 'Work in progress';
      message = revisionRequested
          ? 'Your revision request was sent. The pilot can now submit a new work round.'
          : 'The pilot started the job. Waiting for the next work submission.';
      icon = revisionRequested ? Icons.replay_rounded : Icons.flight_takeoff_rounded;
      color = revisionRequested ? AppColors.orange : AppColors.blue;
      background = revisionRequested ? AppColors.orangeBg : AppColors.blueBg;
    } else if (contract.isSubmitted) {
      title = 'Work submitted';
      message = 'Pilot delivery is waiting for company review.';
      icon = Icons.task_alt_rounded;
      color = AppColors.green;
      background = AppColors.greenBg;
    } else {
      title = contract.statusLabel;
      message = contract.isCompleted
          ? 'This contract has completed its work lifecycle.'
          : 'This contract is in a terminal state.';
      icon = contract.isCompleted
          ? Icons.verified_outlined
          : Icons.info_outline_rounded;
      color = contract.isCompleted ? AppColors.green : AppColors.grey;
      background = contract.isCompleted ? AppColors.greenBg : AppColors.bg;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background.withOpacity(0.76),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
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

  Widget _locationSection(CompanyContractModel contract) {
    final location = _location;

    if (_controller.isLoadingLocation && location == null) {
      return _section(
        title: 'Exact Job Location',
        icon: Icons.location_searching_rounded,
        child: const Row(
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
        ),
      );
    }

    if (location == null && _controller.locationErrorMessage != null) {
      return _section(
        title: 'Exact Job Location',
        icon: Icons.location_off_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.redBg.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sync_problem_rounded, color: AppColors.red, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'The saved location could not be verified from the server. The app will not treat this as a missing location.',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 10.8,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.locationErrorMessage!,
              style: const TextStyle(color: AppColors.red, fontSize: 10.1),
            ),
            const SizedBox(height: 11),
            OutlinedButton.icon(
              onPressed: _acting ? null : () => _load(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry Location Check',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    return _section(
      title: 'Exact Job Location',
      icon: Icons.location_on_outlined,
      child: location == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: contract.canConfigureLocation
                        ? AppColors.orangeBg.withOpacity(0.62)
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        contract.canConfigureLocation
                            ? Icons.add_location_alt_outlined
                            : Icons.lock_clock_outlined,
                        color: contract.canConfigureLocation
                            ? AppColors.orange
                            : AppColors.grey,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          contract.canConfigureLocation
                              ? 'No exact location is saved yet. Add it before the pilot starts work.'
                              : 'Exact location setup becomes available after funding activates the contract.',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 10.8,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_controller.locationErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _controller.locationErrorMessage!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 10.2,
                    ),
                  ),
                ],
                if (contract.canConfigureLocation) ...[
                  const SizedBox(height: 11),
                  FilledButton.icon(
                    onPressed: _acting ? null : _openLocationEditor,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text(
                      'Add Exact Location',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAFBF7), Color(0xFFF3FAFC)],
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
                              _snack('Coordinates copied.');
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
                    ],
                  ),
                ),
                if (contract.canConfigureLocation) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _acting ? null : _openLocationEditor,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                    label: const Text(
                      'Edit Exact Location',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _submissionSection(CompanyContractModel contract) {
    final latest = _submissions.isEmpty ? null : _submissions.last;

    return _section(
      title: 'Work Submission',
      icon: Icons.assignment_turned_in_outlined,
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
                color: AppColors.blueBg.withOpacity(0.62),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No submission yet. The pilot will be able to submit work while the contract is In Progress.',
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
            _infoRow('Submitted', latest.submittedLabel),
            _infoRow('Attachments', '${latest.files.length}'),
            if (latest.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                latest.notes,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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
                      ? AppColors.orangeBg.withOpacity(0.72)
                      : AppColors.greenBg.withOpacity(0.72),
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
            const SizedBox(height: 11),
            OutlinedButton.icon(
              onPressed: _acting ? null : _openLatestSubmission,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 47),
                foregroundColor: contract.isSubmitted ? AppColors.green : AppColors.navy,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                contract.isSubmitted ? Icons.fact_check_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                contract.isSubmitted ? 'Review Latest Submission' : 'View Latest Submission',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
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

  Widget _timeline(CompanyContractModel contract) {
    const steps = <(String, String)>[
      ('pending', 'Contract proposed'),
      ('accepted', 'Pilot accepted'),
      ('active', 'Funded / Active'),
      ('in_progress', 'Work started'),
      ('submitted', 'Work submitted'),
      ('completed', 'Completed'),
    ];
    const order = <String, int>{
      'pending': 0,
      'accepted': 1,
      'active': 2,
      'in_progress': 3,
      'submitted': 4,
      'completed': 5,
    };
    final current = order[contract.normalizedStatus] ?? 0;
    final terminalFailure =
        contract.isRejected || contract.isCancelled || contract.isTerminated;

    return Column(
      children: List.generate(steps.length, (index) {
        final done = index <= current && !terminalFailure;
        return Padding(
          padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.greenBg : AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? AppColors.green.withOpacity(0.25)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle_outlined,
                  size: 14,
                  color: done ? AppColors.green : AppColors.lightGrey,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  steps[index].$2,
                  style: TextStyle(
                    color: done ? AppColors.navy : AppColors.grey,
                    fontSize: 11.2,
                    fontWeight: done ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _payment(CompanyContractModel contract) {
    final raw = contract.latestPayment;
    final payment = raw == null
        ? null
        : PaymentModel.fromJson(raw.toJson());

    if (payment == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: contract.isAccepted ? AppColors.greenBg : AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  contract.isAccepted
                      ? Icons.account_balance_wallet_rounded
                      : Icons.hourglass_top_rounded,
                  color: contract.isAccepted ? AppColors.green : AppColors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contract.isAccepted
                        ? 'Ready to fund ${contract.amountLabel}. Use Fund Contract below.'
                        : 'No payment record returned for this contract yet.',
                    style: TextStyle(
                      color: contract.isAccepted ? AppColors.green : AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _paymentHistoryButton(),
        ],
      );
    }

    final visual = _paymentVisual(payment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: visual.$2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: visual.$1.withOpacity(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visual.$3, color: visual.$1, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.statusLabel,
                      style: TextStyle(
                        color: visual.$1,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _companyPaymentMessage(payment),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 10.6,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _infoRow('Amount', payment.amountLabel),
        if (payment.fundedAt != null)
          _infoRow('Funded', _dateTime(payment.fundedAt)),
        if (payment.eligibleReleaseAt != null)
          _infoRow('Eligible Release', _dateTime(payment.eligibleReleaseAt)),
        if (payment.releasedAt != null)
          _infoRow('Released', _dateTime(payment.releasedAt)),
        if (payment.provider.isNotEmpty)
          _infoRow('Provider', payment.provider),
        if (payment.transactionReference.isNotEmpty)
          _infoRow('Reference', payment.transactionReference),
        if (payment.failureReason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            payment.failureReason,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 10.2,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _paymentHistoryButton(),
      ],
    );
  }

  Widget _paymentHistoryButton() {
    return OutlinedButton.icon(
      onPressed: _acting ? null : _openPaymentHistory,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: const Icon(Icons.receipt_long_outlined, size: 17),
      label: const Text(
        'View Payment History',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  String _companyPaymentMessage(PaymentModel payment) {
    if (payment.isReleasePending) {
      return payment.eligibleReleaseAt == null
          ? 'The contract is completed. Funds are waiting for the backend release window.'
          : 'The contract is completed. Funds become eligible for release at ${_dateTime(payment.eligibleReleaseAt)}.';
    }
    if (payment.isReleased) {
      return 'The payment has been released to the pilot. No further company action is required.';
    }
    if (payment.isFunded || payment.isHeld) {
      return contractPaymentFundedText;
    }
    if (payment.isFailed) {
      return 'The payment is marked as failed. Review the payment record before continuing.';
    }
    if (payment.isRefunded || payment.isPartiallyRefunded) {
      return 'This payment has a refund recorded by the backend.';
    }
    if (payment.isCancelled) {
      return 'This payment was cancelled.';
    }
    return 'The payment record is pending.';
  }

  static const String contractPaymentFundedText =
      'Funding is secured. After the company approves the final work, release eligibility is calculated by the backend.';

  Widget _reviewBar(CompanyContractModel contract) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _acting ? null : _openLatestSubmission,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 19),
          label: const Text(
            'Review Submitted Work',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _fundBar(CompanyContractModel contract) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _controller.isFunding ? null : _fund,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _controller.isFunding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.account_balance_wallet_rounded, size: 19),
          label: Text(
            _controller.isFunding
                ? 'Funding...'
                : 'Fund Contract • ${contract.amountLabel}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
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
                child: Icon(icon, color: AppColors.blue, size: 17),
              ),
              const SizedBox(width: 9),
              Text(
                title,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
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

  String _date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${_date(local)} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _snack(String message, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: error
              ? AppColors.red
              : success
                  ? AppColors.green
                  : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(message),
        ),
      );
  }
}


(Color, Color, IconData) _paymentVisual(PaymentModel payment) {
  if (payment.isReleased) {
    return (AppColors.green, AppColors.greenBg, Icons.check_circle_outline_rounded);
  }
  if (payment.isReleasePending) {
    return (AppColors.orange, AppColors.orangeBg, Icons.schedule_send_outlined);
  }
  if (payment.isFailed || payment.isCancelled) {
    return (AppColors.red, AppColors.redBg, Icons.error_outline_rounded);
  }
  if (payment.isRefunded || payment.isPartiallyRefunded) {
    return (AppColors.orange, AppColors.orangeBg, Icons.undo_rounded);
  }
  return (AppColors.blue, AppColors.blueBg, Icons.account_balance_wallet_outlined);
}

class _ContractBackdrop extends StatelessWidget {
  const _ContractBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5FAFC), AppColors.bg],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

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
            color: onTap == null ? AppColors.lightGrey : AppColors.navy,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.blue),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 38,
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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
