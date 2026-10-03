import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_contract_location_model.dart';
import '../../models/company_contract_model.dart';
import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';
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
    this.initialJob,
    this.initialApplication,
  });

  final int contractId;
  final CompanyContractModel? initialContract;

  /// Optional display context passed by Applications.
  ///
  /// This prevents the mission screen from re-requesting the same job and
  /// applicant endpoints, which also keeps the pilot photo/name/drone and job
  /// title/location exactly consistent with the Applications screen.
  final CompanyJobPostingModel? initialJob;
  final CompanyJobApplicationModel? initialApplication;

  @override
  State<CompanyContractDetailScreen> createState() =>
      _CompanyContractDetailScreenState();
}

class _CompanyContractDetailScreenState
    extends State<CompanyContractDetailScreen> {
  late final CompanyContractController _controller;
  late final TextEditingController _reviewNotesController;

  CompanyContractModel? _contract;
  CompanyJobPostingModel? _job;
  CompanyJobApplicationModel? _application;
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
          _controller.isReviewingSubmission ||
          _controller.isCancelling ||
          _controller.isTerminating;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    _controller = CompanyContractController(
      CompanyContractService(apiClient),
    );
    _reviewNotesController = TextEditingController();

    _contract = widget.initialContract;
    _job = widget.initialJob;
    _application = widget.initialApplication;
    if (_contract != null) {
      _controller.seed(_contract!);
      _initialLoading = false;
    }

    unawaited(_load(initial: true));
  }

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
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

    // COMPANY RULE:
    // GET /company/contracts/{id}/location is allowed for the company at any
    // contract stage. Do not gate company reads by "active" or by pilot
    // visibility rules.
    CompanyContractLocationModel? freshLocation = _location;
    if (freshContract != null) {
      final loadedLocation =
      await _controller.loadLocation(freshContract.id);

      if (loadedLocation != null) {
        freshLocation = loadedLocation;
      } else if (_controller.locationErrorMessage == null) {
        // Valid empty response / no saved exact location.
        freshLocation = null;
      }
      // On a real request error, preserve an already-known location.
    }

    var freshSubmissions = _submissions;
    if (freshContract != null &&
        (freshContract.isInProgress ||
            freshContract.isSubmitted ||
            freshContract.isCompleted)) {
      freshSubmissions =
      await _controller.loadSubmissions(freshContract.id);
    }

    if (!mounted) return;

    setState(() {
      if (freshContract != null) {
        _contract = freshContract;
      } else if (!hadData) {
        _error =
            _controller.errorMessage ?? 'Unable to load this contract.';
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

    CompanyContractLocationModel? location = _location;
    final loadedLocation = await _controller.loadLocation(updated.id);

    if (loadedLocation != null) {
      location = loadedLocation;
    } else if (_controller.locationErrorMessage == null) {
      location = null;
    }

    if (!mounted) return;

    setState(() {
      _contract = updated;
      _location = location;
      _changed = true;
    });

    _snack(
      _location == null
          ? 'Funding confirmed. Contract is Active.'
          : 'Funding confirmed. Contract is Active and the saved exact location is ready.',
      success: true,
    );
  }

  bool _canCompanyEditExactLocation(
      CompanyContractModel contract,
      ) {
    final status = contract.normalizedStatus.trim().toLowerCase();

    return status == 'pending' ||
        status == 'accepted' ||
        status == 'active' ||
        status == 'in_progress' ||
        status == 'submitted';
  }

  Future<void> _openLocationEditor() async {
    final contract = _contract;
    if (contract == null || !_canCompanyEditExactLocation(contract) || _acting) return;

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
      contract.isActive || contract.isInProgress || contract.isSubmitted
          ? 'Exact location saved. It is now visible to the pilot.'
          : 'Exact location saved. It will remain private from the pilot until the contract becomes Active.',
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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanySubmissionReviewScreen(
          contractId: contract.id,
          submission: latest,
        ),
      ),
    );

    if (!mounted || changed != true) return;

    // Do not mutate parent state with objects returned by a route while the
    // route is being removed. Reload from the server after the pop completes.
    _changed = true;
    await _load();
  }

  Future<void> _cancelContract() async {
    final contract = _contract;
    if (contract == null || !contract.canCancelBeforeWork || _acting) return;

    final reason = await _contractActionDialog(
      title: 'Cancel Contract?',
      message:
      'Cancellation is only available before work starts. This action cannot be undone.',
      hint: 'Optional cancellation reason...',
      reasonRequired: false,
      confirmLabel: 'Cancel Contract',
    );
    if (reason == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});
    final updated = await _controller.cancelContract(
      contract.id,
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );
    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to cancel this contract.',
        error: true,
      );
      return;
    }

    setState(() {
      _contract = updated;
      _changed = true;
    });
    await _load();
    if (mounted) {
      _snack('Contract cancelled.', success: true);
    }
  }

  Future<void> _terminateContract() async {
    final contract = _contract;
    if (contract == null || !contract.canTerminateMidWork || _acting) return;

    final reason = await _contractActionDialog(
      title: 'Terminate Contract?',
      message:
      'This stops an in-progress contract. A reason is required and the backend will handle the payment consequence.',
      hint: 'Explain why this contract must be terminated...',
      reasonRequired: true,
      confirmLabel: 'Terminate Contract',
    );
    if (reason == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});
    final updated = await _controller.terminateContract(
      contract.id,
      reason: reason.trim(),
    );
    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to terminate this contract.',
        error: true,
      );
      return;
    }

    setState(() {
      _contract = updated;
      _changed = true;
    });
    await _load();
    if (mounted) {
      _snack('Contract terminated.', success: true);
    }
  }

  Future<String?> _contractActionDialog({
    required String title,
    required String message,
    required String hint,
    required bool reasonRequired,
    required String confirmLabel,
  }) async {
    String draft = '';
    String? validation;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                title,
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
                    message,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (value) {
                      draft = value;
                      if (validation != null && value.trim().isNotEmpty) {
                        setLocalState(() => validation = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: hint,
                      errorText: validation,
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
                  child: const Text('Keep Contract'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = draft.trim();
                    if (reasonRequired && value.isEmpty) {
                      setLocalState(
                            () => validation = 'A reason is required.',
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }


  ContractSubmissionModel? get _latestSubmission =>
      _submissions.isEmpty ? null : _submissions.last;

  Future<void> _referenceRequestRevision() async {
    final contract = _contract;
    final submission = _latestSubmission;

    if (contract == null ||
        submission == null ||
        !submission.isSubmitted ||
        _acting) {
      return;
    }

    final note = _reviewNotesController.text.trim();
    if (note.isEmpty) {
      _snack(
        'Add revision notes so the pilot knows exactly what to change.',
        error: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {});

    final result = await _controller.requestRevision(
      contract.id,
      submission.id,
      reviewNotes: note,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to request revision.',
        error: true,
      );
      return;
    }

    _reviewNotesController.clear();
    _changed = true;
    await _load();

    if (mounted) {
      _snack('Revision request sent to the pilot.', success: true);
    }
  }

  Future<void> _referenceApproveWork() async {
    final contract = _contract;
    final submission = _latestSubmission;

    if (contract == null ||
        submission == null ||
        !submission.isSubmitted ||
        _acting) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {});

    final note = _reviewNotesController.text.trim();

    final result = await _controller.approveSubmission(
      contract.id,
      submission.id,
      reviewNotes: note.isEmpty ? null : note,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to approve submission.',
        error: true,
      );
      return;
    }

    _reviewNotesController.clear();
    _changed = true;
    await _load();

    if (mounted) {
      _snack('Work approved. Mission completed.', success: true);
    }
  }

  bool _referenceFileIsImage(ContractSubmissionFileModel file) {
    final source = '${file.displayName} ${file.url}'.toLowerCase();
    return source.endsWith('.png') ||
        source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.webp') ||
        source.contains('.png?') ||
        source.contains('.jpg?') ||
        source.contains('.jpeg?') ||
        source.contains('.webp?');
  }

  bool _referenceFileIsPdf(ContractSubmissionFileModel file) {
    final source = '${file.displayName} ${file.url}'.toLowerCase();
    return source.contains('.pdf');
  }

  Future<void> _openReferenceSubmissionFile(
      ContractSubmissionFileModel file,
      ) async {
    final url = file.url.trim();

    if (url.isEmpty) {
      _snack('This file does not have a preview URL.', error: true);
      return;
    }

    if (_referenceFileIsImage(file)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to preview this image.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      _snack(
        _referenceFileIsPdf(file)
            ? 'PDF link copied.'
            : 'File link copied.',
      );
    }
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
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FBFC),
          body: SafeArea(
            child: Column(
              children: [
                _referenceTopBar(contract),
                Expanded(
                  child: _initialLoading && contract == null
                      ? const _DetailLoading()
                      : _error != null && contract == null
                      ? _ErrorState(
                    message: _error!,
                    onRetry: () => _load(),
                  )
                      : _referenceContent(contract!),
                ),
              ],
            ),
          ),
          bottomNavigationBar: contract?.canFund == true
              ? _referenceFundBar(contract!)
              : contract?.canReviewSubmission == true &&
              _latestSubmission?.isSubmitted == true
              ? _referenceReviewBar()
              : null,
        ),
      ),
    );
  }


  Widget _referenceTopBar(CompanyContractModel? contract) {
    final title = _job?.title.trim().isNotEmpty == true
        ? _job!.title.trim()
        : 'Mission';

    final location = _publicJobLocation();

    final category = _job?.serviceCategory.trim().isNotEmpty == true
        ? _referencePretty(_job!.serviceCategory)
        : '';

    final status = contract == null
        ? ''
        : _referencePretty(contract.normalizedStatus);

    final meta = <String>[
      if (category.isNotEmpty) category,
      if (status.isNotEmpty) status,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ReferenceMissionPalette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _ReferenceMissionPalette.navy.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: _ReferenceMissionPalette.navy,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ReferenceMissionPalette.tealDark,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11.5,
                        color: _ReferenceMissionPalette.muted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ReferenceMissionPalette.muted,
                            fontSize: 9.7,
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
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: _ReferenceMissionPalette.navy,
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  unawaited(_load());
                  break;
                case 'location':
                  unawaited(_openLocationEditor());
                  break;
                case 'payments':
                  unawaited(_openPaymentHistory());
                  break;
                case 'contracts':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompanyContractsScreen(),
                    ),
                  );
                  break;
                case 'cancel':
                  unawaited(_cancelContract());
                  break;
                case 'terminate':
                  unawaited(_terminateContract());
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
              if (contract != null &&
                  _canCompanyEditExactLocation(contract))
                PopupMenuItem(
                  value: 'location',
                  child: Text(
                    _location == null
                        ? 'Add exact location'
                        : 'Edit exact location',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const PopupMenuItem(
                value: 'payments',
                child: Text(
                  'Payment history',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const PopupMenuItem(
                value: 'contracts',
                child: Text(
                  'All contracts',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (contract?.canCancelBeforeWork == true)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text(
                    'Cancel contract',
                    style: TextStyle(
                      fontSize: 12,
                      color: _ReferenceMissionPalette.red,
                    ),
                  ),
                ),
              if (contract?.canTerminateMidWork == true)
                const PopupMenuItem(
                  value: 'terminate',
                  child: Text(
                    'Terminate contract',
                    style: TextStyle(
                      fontSize: 12,
                      color: _ReferenceMissionPalette.red,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceContent(CompanyContractModel contract) {
    final latest = _latestSubmission;

    return RefreshIndicator(
      color: _ReferenceMissionPalette.teal,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 30),
        children: [
          _referencePilotCard(),
          const SizedBox(height: 11),
          _ReferenceMissionProgress(
            status: contract.normalizedStatus,
          ),
          const SizedBox(height: 12),

          if (contract.isSubmitted && latest != null) ...[
            _referenceReviewCallout(),
            const SizedBox(height: 10),
          ] else if (contract.isInProgress) ...[
            _referenceStateCallout(
              icon: Icons.flight_takeoff_rounded,
              title: 'Work in progress',
              message:
              'The pilot is working on this mission. The next step is work submission.',
            ),
            const SizedBox(height: 10),
          ] else if (contract.isActive) ...[
            _referenceStateCallout(
              icon: Icons.verified_outlined,
              title: _location == null
                  ? 'Mission funded · exact location needed'
                  : 'Mission funded · ready for work',
              message: _location == null
                  ? 'No exact location is saved yet. Add it before the pilot starts work.'
                  : 'The saved exact location is now visible to the pilot.',
            ),
            const SizedBox(height: 10),
          ] else if (contract.isAccepted) ...[
            _referenceStateCallout(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Pilot accepted the agreement',
              message:
              'Fund the contract to activate the mission. You can set the exact location before funding; the pilot only sees it once the contract is Active.',
            ),
            const SizedBox(height: 10),
          ],

          _referenceMissionDetails(contract),

          const SizedBox(height: 10),
          _referenceLocationCard(contract),

          if (latest != null) ...[
            const SizedBox(height: 10),
            _referenceSubmittedFiles(latest),
          ],

          if (contract.isSubmitted &&
              latest?.isSubmitted == true) ...[
            const SizedBox(height: 10),
            _referenceReviewNotesField(),
          ],

          const SizedBox(height: 10),
          _referencePaymentStatus(contract),

          const SizedBox(height: 10),
          _referenceMissionHistory(contract),

          if (contract.terms.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReferenceMissionCard(
              title: 'Agreement Terms',
              icon: Icons.description_outlined,
              child: Text(
                contract.terms.trim(),
                style: const TextStyle(
                  color: _ReferenceMissionPalette.text,
                  fontSize: 10.7,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _referencePilotCard() {
    final pilot = _application?.pilotProfile;

    final name = pilot?.displayName.trim().isNotEmpty == true
        ? pilot!.displayName.trim()
        : 'Pilot';

    final photo = pilot?.profilePhoto.trim() ?? '';
    final experience = pilot?.experienceLabel.trim() ?? '';
    final nationality = pilot?.nationality.trim() ?? '';
    final location = pilot?.location.trim() ?? '';

    final detail = <String>[
      if (experience.isNotEmpty) experience,
      if (nationality.isNotEmpty) nationality,
      if (nationality.isEmpty && location.isNotEmpty) location,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _ReferenceMissionPalette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF2F4),
            ),
            child: ClipOval(
              child: photo.isNotEmpty
                  ? Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _referencePilotFallback(name),
              )
                  : _referencePilotFallback(name),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ReferenceMissionPalette.navy,
                          fontSize: 12.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (pilot?.verified == true) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: _ReferenceMissionPalette.green,
                      ),
                    ],
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ReferenceMissionPalette.muted,
                      fontSize: 10.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _ReferenceMissionPalette.tealSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 17,
              color: _ReferenceMissionPalette.tealDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referencePilotFallback(String name) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF70C2C8),
            Color(0xFF3E8290),
          ],
        ),
      ),
      child: Text(
        _referenceInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _referenceReviewCallout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceMissionIconBox(
            icon: Icons.assignment_turned_in_outlined,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work submitted — your review is needed',
                  style: TextStyle(
                    color: _ReferenceMissionPalette.navy,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'The pilot submitted the deliverables for this mission. Review the files, then approve or request a revision.',
                  style: TextStyle(
                    color: _ReferenceMissionPalette.muted,
                    fontSize: 9.9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceStateCallout({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: _ReferenceMissionPalette.tealSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReferenceMissionIconBox(icon: icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.navy,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.muted,
                    fontSize: 9.9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceMissionDetails(CompanyContractModel contract) {
    final drone = _application?.drone;

    final publicLocation = _publicJobLocation();
    final exactLocation = _location?.address.trim() ?? '';

    final location = exactLocation.isNotEmpty
        ? exactLocation
        : publicLocation.isNotEmpty
        ? publicLocation
        : 'Location not provided';

    final droneText = drone == null
        ? 'Selected drone'
        : [
      drone.displayName,
      ...drone.capabilities.take(3).map(_referencePretty),
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _ReferenceMissionPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ReferenceMissionIconBox(
                icon: Icons.location_on_outlined,
              ),
              SizedBox(width: 8),
              Text(
                'Mission Details',
                style: TextStyle(
                  color: _ReferenceMissionPalette.navy,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: _ReferenceMissionPalette.tealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: _ReferenceMissionPalette.tealDark,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: _ReferenceMissionPalette.muted,
                          fontSize: 9.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: const TextStyle(
                          color: _ReferenceMissionPalette.navy,
                          fontSize: 10.7,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReferenceMissionInfoTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Schedule',
                  value: _referenceContractDates(contract),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReferenceMissionInfoTile(
                  icon: Icons.payments_outlined,
                  label: 'Agreement',
                  value:
                  '${contract.amountLabel}\n${contract.paymentTypeLabel}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ReferenceMissionInfoTile(
            icon: Icons.flight_outlined,
            label: 'Selected drone',
            value: droneText,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _referenceLocationCard(CompanyContractModel contract) {
    final location = _location;
    final canEdit = _canCompanyEditExactLocation(contract);
    final loadError = _controller.locationErrorMessage;

    return _ReferenceMissionCard(
      title: 'Exact Job Location',
      icon: Icons.my_location_outlined,
      trailing: canEdit
          ? TextButton(
        onPressed: _acting ? null : _openLocationEditor,
        style: TextButton.styleFrom(
          foregroundColor: _ReferenceMissionPalette.tealDark,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 7),
        ),
        child: Text(
          location == null ? 'Add' : 'Edit',
          style: const TextStyle(
            fontSize: 10.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      )
          : null,
      child: _controller.isLoadingLocation && location == null
          ? const Row(
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ReferenceMissionPalette.tealDark,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading exact location...',
            style: TextStyle(
              color: _ReferenceMissionPalette.muted,
              fontSize: 10.2,
            ),
          ),
        ],
      )
          : location != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.address,
            style: const TextStyle(
              color: _ReferenceMissionPalette.navy,
              fontSize: 10.9,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              location.coordinatesLabel,
              style: const TextStyle(
                color: _ReferenceMissionPalette.muted,
                fontSize: 9.4,
              ),
            ),
          ),
          if (location.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              location.notes.trim(),
              style: const TextStyle(
                color: _ReferenceMissionPalette.text,
                fontSize: 9.8,
                height: 1.35,
              ),
            ),
          ],
        ],
      )
          : loadError != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The exact location could not be refreshed right now.',
            style: TextStyle(
              color: _ReferenceMissionPalette.text,
              fontSize: 10.3,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 7),
          TextButton.icon(
            onPressed: _acting ? null : () => _load(),
            style: TextButton.styleFrom(
              foregroundColor:
              _ReferenceMissionPalette.tealDark,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 15,
            ),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 10.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      )
          : Text(
        contract.isCompleted ||
            contract.isCancelled ||
            contract.isTerminated
            ? 'No exact location was saved for this contract.'
            : 'No exact location has been saved yet.',
        style: const TextStyle(
          color: _ReferenceMissionPalette.muted,
          fontSize: 10.3,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _referenceSubmittedFiles(ContractSubmissionModel submission) {
    return _ReferenceMissionCard(
      title: 'Submitted Files',
      icon: Icons.folder_rounded,
      trailing: Text(
        '${submission.files.length} file${submission.files.length == 1 ? '' : 's'}',
        style: const TextStyle(
          color: _ReferenceMissionPalette.muted,
          fontSize: 9.8,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: submission.files.isEmpty
          ? const Text(
        'No files were included in this submission.',
        style: TextStyle(
          color: _ReferenceMissionPalette.muted,
          fontSize: 10.4,
        ),
      )
          : SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: submission.files.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final file = submission.files[index];

            return _ReferenceSubmissionFileCard(
              file: file,
              isImage: _referenceFileIsImage(file),
              isPdf: _referenceFileIsPdf(file),
              onTap: () => _openReferenceSubmissionFile(file),
            );
          },
        ),
      ),
    );
  }

  Widget _referenceReviewNotesField() {
    return _ReferenceMissionCard(
      title: 'Review Notes',
      icon: Icons.chat_bubble_outline_rounded,
      trailing: const Text(
        '(optional for approval)',
        style: TextStyle(
          color: _ReferenceMissionPalette.muted,
          fontSize: 9.3,
        ),
      ),
      child: TextField(
        controller: _reviewNotesController,
        minLines: 2,
        maxLines: 4,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: _ReferenceMissionPalette.text,
          fontSize: 10.6,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText:
          'Add notes about the work, or revision instructions if needed...',
          hintStyle: const TextStyle(
            color: Color(0xFFA2AFB8),
            fontSize: 10.2,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FBFC),
          contentPadding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: _ReferenceMissionPalette.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: _ReferenceMissionPalette.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: _ReferenceMissionPalette.teal,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _referencePaymentStatus(CompanyContractModel contract) {
    final raw = contract.latestPayment;
    final payment =
    raw == null ? null : PaymentModel.fromJson(raw.toJson());

    String title;
    String subtitle;

    if (payment == null) {
      title = contract.isAccepted
          ? 'Ready to fund'
          : 'Payment status';
      subtitle = contract.isAccepted
          ? '${contract.amountLabel} is waiting for company funding.'
          : 'No payment record is available yet.';
    } else if (payment.isReleased) {
      title = 'Released';
      subtitle = 'Payment was released to the pilot.';
    } else if (payment.isReleasePending) {
      title = 'Release pending';
      subtitle = 'Completed · waiting for the backend release window.';
    } else if (payment.isFunded || payment.isHeld) {
      title = 'Funded';
      subtitle = contract.isSubmitted
          ? 'Funds are secured · release follows approved completion.'
          : 'Funds are secured for this mission.';
    } else {
      title = payment.statusLabel;
      subtitle = _companyPaymentMessage(payment);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPaymentHistory,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const _ReferenceMissionIconBox(
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ReferenceMissionPalette.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReferenceMissionPalette.muted,
                        fontSize: 9.7,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                color: _ReferenceMissionPalette.muted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _referenceMissionHistory(CompanyContractModel contract) {
    final history = <_ReferenceHistoryItem>[];

    final application = _application;
    if (application?.createdAt != null) {
      history.add(
        _ReferenceHistoryItem(
          label: 'Application submitted',
          time: _dateTime(application!.createdAt),
        ),
      );
    }

    if (application?.decidedAt != null &&
        application?.isAccepted == true) {
      history.add(
        _ReferenceHistoryItem(
          label: 'Application accepted',
          time: _dateTime(application!.decidedAt),
        ),
      );
    }

    if (contract.createdAt != null) {
      history.add(
        _ReferenceHistoryItem(
          label: 'Contract created',
          time: _dateTime(contract.createdAt),
        ),
      );
    }

    final rawPayment = contract.latestPayment;
    if (rawPayment != null) {
      final payment = PaymentModel.fromJson(rawPayment.toJson());
      if (payment.fundedAt != null) {
        history.add(
          _ReferenceHistoryItem(
            label: 'Mission funded',
            time: _dateTime(payment.fundedAt),
          ),
        );
      }
      if (payment.releasedAt != null) {
        history.add(
          _ReferenceHistoryItem(
            label: 'Payment released',
            time: _dateTime(payment.releasedAt),
          ),
        );
      }
    }

    final latest = _latestSubmission;
    if (latest != null) {
      history.add(
        _ReferenceHistoryItem(
          label: latest.isApproved
              ? 'Work approved'
              : latest.isRevisionRequested
              ? 'Revision requested'
              : 'Work submitted',
          time: latest.submittedLabel,
        ),
      );
    }

    if (history.isEmpty) {
      history.add(
        const _ReferenceHistoryItem(
          label: 'Contract lifecycle',
          time: 'Current state',
        ),
      );
    }

    return _ReferenceMissionCard(
      title: 'Mission History',
      icon: Icons.history_rounded,
      child: Column(
        children: List.generate(history.length, (index) {
          final item = history[index];
          final last = index == history.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 17,
                child: Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _ReferenceMissionPalette.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!last)
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFCFE8E8),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: _ReferenceMissionPalette.text,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: _ReferenceMissionPalette.muted,
                          fontSize: 9.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _referenceDetailRow(
      String label,
      String value, {
        double bottomPadding = 6,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                color: _ReferenceMissionPalette.muted,
                fontSize: 9.9,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _ReferenceMissionPalette.text,
                fontSize: 10.2,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _publicJobLocation() {
    final job = _job;
    if (job == null) return '';

    final parts = <String>[
      job.city,
      job.state,
      job.country,
    ].where((value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(', ');

    return job.region.trim();
  }

  String _referenceContractDates(CompanyContractModel contract) {
    final start = _date(contract.startDate);
    final end = contract.endDate == null ? '' : _date(contract.endDate);

    if (contract.endDate != null) {
      return '$start → $end';
    }
    return start;
  }

  String _referenceInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return 'P';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String _referencePretty(String value) {
    final clean = value
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (clean.isEmpty) return '';

    return clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
      '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
    )
        .join(' ');
  }

  Widget _referenceReviewBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: _ReferenceMissionPalette.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _ReferenceMissionPalette.navy.withOpacity(.045),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed:
                  _acting ? null : _referenceRequestRevision,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    _ReferenceMissionPalette.tealDark,
                    side: const BorderSide(
                      color: _ReferenceMissionPalette.teal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Request revision',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: SizedBox(
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF14B8BF),
                        Color(0xFF08A0B4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                    _acting ? null : _referenceApproveWork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _controller.isReviewingSubmission
                        ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.check_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Approve & complete',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _referenceFundBar(CompanyContractModel contract) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: _ReferenceMissionPalette.border,
            ),
          ),
        ),
        child: SizedBox(
          height: 47,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF14B8BF),
                  Color(0xFF08A0B4),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton.icon(
              onPressed:
              _controller.isFunding ? null : _fund,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _controller.isFunding
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
              ),
              label: Text(
                _controller.isFunding
                    ? 'Funding...'
                    : 'Fund contract · ${contract.amountLabel}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
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
          if (contract.canCancelBeforeWork || contract.canTerminateMidWork) ...[
            const SizedBox(height: 12),
            _contractManagementSection(contract),
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
    } else if (contract.isCompleted) {
      title = 'Contract completed';
      message =
      'The final work was approved. Payment release timing is handled by the backend.';
      icon = Icons.verified_outlined;
      color = AppColors.green;
      background = AppColors.greenBg;
    } else if (contract.isCancelled) {
      title = 'Contract cancelled';
      message = 'This contract was cancelled before work started.';
      icon = Icons.cancel_outlined;
      color = AppColors.red;
      background = AppColors.redBg;
    } else if (contract.isTerminated) {
      title = 'Contract terminated';
      message =
      'This contract was terminated after work started. Payment handling follows backend policy.';
      icon = Icons.stop_circle_outlined;
      color = AppColors.red;
      background = AppColors.redBg;
    } else {
      title = contract.statusLabel;
      message = 'This contract is in a terminal state.';
      icon = Icons.info_outline_rounded;
      color = AppColors.grey;
      background = AppColors.bg;
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
                        : 'No exact location has been saved yet.',
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

  Widget _contractManagementSection(CompanyContractModel contract) {
    final isTerminate = contract.canTerminateMidWork;
    return _section(
      title: 'Contract Management',
      icon: Icons.admin_panel_settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redBg.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isTerminate
                  ? 'Work is already in progress. Termination requires a reason and may affect the funded payment according to backend policy.'
                  : 'You can cancel only before the pilot starts work. The reason is optional.',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10.7,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _acting
                ? null
                : isTerminate
                ? _terminateContract
                : _cancelContract,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withOpacity(0.40)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _controller.isCancelling || _controller.isTerminating
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.red,
              ),
            )
                : Icon(
              isTerminate
                  ? Icons.stop_circle_outlined
                  : Icons.cancel_outlined,
              size: 18,
            ),
            label: Text(
              _controller.isCancelling
                  ? 'Cancelling...'
                  : _controller.isTerminating
                  ? 'Terminating...'
                  : isTerminate
                  ? 'Terminate Contract'
                  : 'Cancel Contract',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
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


class _ReferenceMissionPalette {
  static const navy = Color(0xFF0A2D46);
  static const text = Color(0xFF40596A);
  static const muted = Color(0xFF80919D);
  static const border = Color(0xFFE0E9EC);
  static const teal = Color(0xFF12AEBB);
  static const tealDark = Color(0xFF0A91A6);
  static const tealSoft = Color(0xFFEAF8F7);
  static const green = Color(0xFF12A789);
  static const red = Color(0xFFE45D55);
}

class _ReferenceMissionIconBox extends StatelessWidget {
  const _ReferenceMissionIconBox({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF6F3),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        size: 16,
        color: _ReferenceMissionPalette.tealDark,
      ),
    );
  }
}

class _ReferenceMissionCard extends StatelessWidget {
  const _ReferenceMissionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _ReferenceMissionPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: _ReferenceMissionPalette.tealDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.navy,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _ReferenceMissionProgress extends StatelessWidget {
  const _ReferenceMissionProgress({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Agreement',
      'Funded',
      'Work',
      'Review',
      'Complete',
    ];

    final normalized = status.trim().toLowerCase();

    int current;
    int completedThrough;
    bool allComplete = false;

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
        allComplete = true;
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
              final segment = index ~/ 2;
              final active =
                  allComplete || segment < completedThrough;

              return Expanded(
                child: Container(
                  height: 2,
                  color: active
                      ? _ReferenceMissionPalette.tealDark
                      : const Color(0xFFD7E1E6),
                ),
              );
            }

            final step = index ~/ 2;
            final completed =
                allComplete || step <= completedThrough;
            final active = !allComplete && step == current;

            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? _ReferenceMissionPalette.tealDark
                    : Colors.white,
                border: Border.all(
                  color: completed || active
                      ? _ReferenceMissionPalette.tealDark
                      : const Color(0xFFC7D2D8),
                  width: active && !completed ? 2 : 1.3,
                ),
              ),
              child: completed
                  ? const Icon(
                Icons.check_rounded,
                size: 12,
                color: Colors.white,
              )
                  : active
                  ? Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color:
                    _ReferenceMissionPalette.tealDark,
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
                allComplete ||
                    index <= completedThrough ||
                    index == current;

            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: emphasized
                      ? _ReferenceMissionPalette.navy
                      : _ReferenceMissionPalette.muted,
                  fontSize: 8.6,
                  fontWeight: emphasized
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ReferenceSubmissionFileCard extends StatelessWidget {
  const _ReferenceSubmissionFileCard({
    required this.file,
    required this.isImage,
    required this.isPdf,
    required this.onTap,
  });

  final ContractSubmissionFileModel file;
  final bool isImage;
  final bool isPdf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _ReferenceMissionPalette.border,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: isImage && file.url.trim().isNotEmpty
                        ? Image.network(
                      file.url.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ReferenceSubmissionFileFallback(
                            isPdf: isPdf,
                            name: file.displayName,
                          ),
                    )
                        : _ReferenceSubmissionFileFallback(
                      isPdf: isPdf,
                      name: file.displayName,
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.94),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      isImage
                          ? Icons.open_in_full_rounded
                          : Icons.download_rounded,
                      size: 13,
                      color: _ReferenceMissionPalette.tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceSubmissionFileFallback extends StatelessWidget {
  const _ReferenceSubmissionFileFallback({
    required this.isPdf,
    required this.name,
  });

  final bool isPdf;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            color: isPdf
                ? _ReferenceMissionPalette.red
                : _ReferenceMissionPalette.tealDark,
            size: 23,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ReferenceMissionPalette.text,
              fontSize: 8.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceHistoryItem {
  const _ReferenceHistoryItem({
    required this.label,
    required this.time,
  });

  final String label;
  final String time;
}


class _ReferenceMissionInfoTile extends StatelessWidget {
  const _ReferenceMissionInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE5ECEF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7F6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 14,
              color: _ReferenceMissionPalette.tealDark,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.muted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: fullWidth ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReferenceMissionPalette.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
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
