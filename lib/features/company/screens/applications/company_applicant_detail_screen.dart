import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../controllers/company_job_controller.dart';
import '../../models/company_contract_model.dart';
import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';
import '../../services/company_contract_service.dart';
import '../applications/company_document_viewer_screen.dart';
import '../contract/company_contract_detail_screen.dart';
import '../contract/company_contracts_screen.dart';
import '../contract/create_company_contract_screen.dart';

class CompanyApplicantDetailScreen extends StatefulWidget {
  const CompanyApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.application,
    this.initialJob,
  });

  final int jobId;
  final CompanyJobApplicationModel application;

  /// The nested job_posting already returned by GET /company/applicants.
  /// Passing it avoids a visible second-stage job load when opening details.
  final CompanyJobPostingModel? initialJob;

  @override
  State<CompanyApplicantDetailScreen> createState() =>
      _CompanyApplicantDetailScreenState();
}

class _CompanyApplicantDetailScreenState
    extends State<CompanyApplicantDetailScreen> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _cachePrefix = 'company_applicant_detail_v10_';

  late final CompanyJobService _jobService;
  late final CompanyJobController _controller;
  late final CompanyContractService _contractService;
  late final CompanyContractController _contractController;
  late CompanyJobApplicationModel _application;

  CompanyJobPostingModel? _job;
  CompanyApplicantPilotModel? _pilot;
  CompanyApplicantDroneModel? _committedDrone;
  List<CompanyPilotCredentialModel> _credentials = const [];
  CompanyContractModel? _createdContract;

  String? _cacheKey;
  String? _backgroundError;
  int? _openingMediaId;

  bool _changed = false;
  bool _backgroundRefreshing = false;
  bool _cacheReadFinished = false;
  bool _supportLoadedOnce = false;
  bool _openingContractScreen = false;
  bool _contractLookupLoading = true;
  String? _contractLookupError;
  int _referenceTab = 0;

  bool get _acting =>
      _controller.isAcceptingApplicant ||
          _controller.isRejectingApplicant;

  bool get _supportLoading =>
      _controller.isLoadingApplicantPilotProfile ||
          _controller.isLoadingApplicantCredentials ||
          _controller.isLoadingApplicantDrones;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    _jobService = CompanyJobService(apiClient);
    _controller = CompanyJobController(_jobService);
    _contractService = CompanyContractService(apiClient);
    _contractController = CompanyContractController(_contractService);

    _application = widget.application;
    _job = widget.initialJob;
    _pilot = widget.application.pilotProfile;
    _committedDrone = widget.application.drone;
    _credentials = const <CompanyPilotCredentialModel>[];

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadCache();
    if (!mounted) return;
    unawaited(_refreshInBackground());
  }

  // ==========================================================================
  // LOCAL-FIRST CACHE
  // ==========================================================================

  Future<void> _loadCache() async {
    try {
      final userId = await UserSessionStorage.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        return;
      }

      _cacheKey =
      '$_cachePrefix${userId}_${widget.jobId}_${widget.application.id}';

      final raw = await _storage.read(key: _cacheKey!);
      if (raw == null || raw.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _cacheReadFinished = true);
        unawaited(_saveCache());
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        final cachedApplication = map['application'];
        final cachedCredentials = map['credentials'];
        final cachedContract = map['created_contract'];

        CompanyApplicantPilotModel? cachedPilot;
        CompanyApplicantDroneModel? cachedDrone;
        List<CompanyPilotCredentialModel> cachedCredentialModels = const [];
        CompanyContractModel? cachedContractModel;

        if (cachedApplication is Map) {
          final cached = CompanyJobApplicationModel.fromJson(
            Map<String, dynamic>.from(cachedApplication),
          );
          cachedPilot = cached.pilotProfile;
          cachedDrone = cached.drone;
        }

        if (cachedContract is Map) {
          cachedContractModel = CompanyContractModel.fromJson(
            Map<String, dynamic>.from(cachedContract),
          );
        }

        if (cachedCredentials is List) {
          cachedCredentialModels = cachedCredentials
              .whereType<Map>()
              .map(
                (item) => CompanyPilotCredentialModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
              .toList(growable: false);
        }

        if (!mounted) return;
        setState(() {
          if (cachedPilot != null) {
            _pilot = _pilot == null
                ? cachedPilot
                : _pilot!.mergeWith(cachedPilot);
          }

          if (cachedDrone != null) {
            _committedDrone = _preferRicherDrone(
              current: _committedDrone,
              incoming: cachedDrone,
            );
          }

          if (cachedContractModel != null) {
            _createdContract = cachedContractModel;
          }

          if (cachedCredentialModels.isNotEmpty) {
            _credentials = cachedCredentialModels;
          }

          _cacheReadFinished = true;
        });
        return;
      }
    } catch (_) {
      // Keep the application passed from the previous screen visible.
    }

    if (!mounted) return;
    setState(() => _cacheReadFinished = true);
  }

  Future<void> _saveCache() async {
    final key = _cacheKey;
    if (key == null) return;

    try {
      final enrichedApplication = _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );

      await _storage.write(
        key: key,
        value: jsonEncode({
          'version': 10,
          'saved_at': DateTime.now().toIso8601String(),
          'application': enrichedApplication.toJson(),
          'credentials': _credentials.map((item) => item.toJson()).toList(),
          'created_contract': _createdContract?.toJson(),
        }),
      );
    } catch (_) {}
  }

  // ==========================================================================
  // BACKGROUND REFRESH
  // ==========================================================================

  Future<CompanyJobPostingModel?> _loadJobSafely() async {
    final initial = _job;

    if (initial != null) {
      // The /company/applicants response already returned the job_posting.
      // It is enough for the first render.
      return initial;
    }

    try {
      return await _jobService.getJobDetails(
        widget.jobId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _precacheCoreImages({
    required CompanyJobPostingModel? job,
    required CompanyApplicantPilotModel? pilot,
    required CompanyApplicantDroneModel? drone,
  }) async {
    if (!mounted) return;

    final urls = <String>{
      if (pilot?.profilePhoto.trim().isNotEmpty == true)
        pilot!.profilePhoto.trim(),
      if (drone?.imageUrl.trim().isNotEmpty == true)
        drone!.imageUrl.trim(),
      if (_referenceJobImage(job).trim().isNotEmpty)
        _referenceJobImage(job).trim(),
    };

    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(NetworkImage(url), context);
        } catch (_) {}
      }),
    );
  }

  Future<void> _refreshInBackground() async {
    if (_backgroundRefreshing) return;

    _backgroundRefreshing = true;

    if (mounted) {
      setState(() {
        _backgroundError = null;
      });
    }

    try {
      // ----------------------------------------------------------------------
      // GET /company/applicants already gave us:
      // - pilot_profile (name/photo/location/experience)
      // - drone (make/model/specs)
      // - job_posting
      //
      // So we do NOT call job-specific applicants again here. That endpoint is
      // unnecessary for the first render and can return [] even though the
      // all-company applicants response already contains this application.
      // ----------------------------------------------------------------------

      final freshJobFuture =
      _loadJobSafely();

      Future<CompanyContractModel?>? contractFuture;

      if (_application.isAccepted) {
        final contractJobId =
        _application.jobPostingId > 0
            ? _application.jobPostingId
            : widget.jobId;

        contractFuture =
            _contractController
                .loadExistingContract(
              applicationId: _application.id,
              jobId: contractJobId,
            );
      }

      CompanyApplicantPilotModel? resolvedPilot =
          _pilot ??
              _application.pilotProfile;

      CompanyApplicantDroneModel? resolvedDrone =
          _committedDrone ??
              _application.drone;

      var resolvedCredentials =
      <CompanyPilotCredentialModel>[
        ..._credentials,
      ];

      final errorParts = <String>[];

      // The response you supplied contains pilot profile photo/name directly,
      // so only enrich the pilot if those actual display fields are missing.
      final pilotNeedsEnrichment =
          resolvedPilot == null ||
              resolvedPilot.displayName.trim().isEmpty ||
              resolvedPilot.profilePhoto.trim().isEmpty;

      // The supplied /company/applicants response contains NO drone image URL.
      // Therefore image enrichment must come from the pilot-drones endpoint.
      final droneNeedsEnrichment =
          resolvedDrone == null ||
              resolvedDrone.displayName.trim().isEmpty ||
              resolvedDrone.imageUrl.trim().isEmpty;

      bool? pilotSuccess;
      bool? credentialsSuccess;
      bool? dronesSuccess;

      final supportRequests =
      <Future<void>>[];

      if (pilotNeedsEnrichment) {
        supportRequests.add(
          _controller
              .loadApplicantPilotProfile(
            _application.pilotProfileId,
          )
              .then(
                (value) =>
            pilotSuccess = value,
          ),
        );
      }

      if (resolvedCredentials.isEmpty) {
        supportRequests.add(
          _controller
              .loadApplicantCredentials(
            _application.pilotProfileId,
          )
              .then(
                (value) =>
            credentialsSuccess = value,
          ),
        );
      }

      if (droneNeedsEnrichment) {
        supportRequests.add(
          _controller
              .loadApplicantDrones(
            pilotProfileId:
            _application.pilotProfileId,
            committedDroneId:
            _application.droneId,
          )
              .then(
                (value) =>
            dronesSuccess = value,
          ),
        );
      }

      // Start job/contract/support work together.
      final freshJob = await freshJobFuture;

      if (supportRequests.isNotEmpty) {
        await Future.wait(
          supportRequests,
        );
      }

      if (!mounted) return;

      if (pilotSuccess == true) {
        final freshPilot =
            _controller.applicantPilotProfile;

        if (freshPilot != null) {
          resolvedPilot =
          resolvedPilot == null
              ? freshPilot
              : resolvedPilot.mergeWith(
            freshPilot,
          );

        }
      } else if (pilotSuccess == false) {
        final value =
            _controller
                .applicantPilotProfileErrorMessage
                ?.trim() ??
                '';

        if (value.isNotEmpty) {
          errorParts.add(value);
        }
      }

      if (credentialsSuccess == true) {
        resolvedCredentials =
            _controller.applicantCredentials;
      } else if (credentialsSuccess ==
          false) {
        final value =
            _controller
                .applicantCredentialsErrorMessage
                ?.trim() ??
                '';

        if (value.isNotEmpty) {
          errorParts.add(value);
        }
      }

      if (dronesSuccess == true) {
        final fullDrone =
            _controller
                .committedApplicantDrone;

        if (fullDrone != null) {
          // The dedicated pilot-drones response is authoritative for the
          // committed drone image. Do not prefer the image-less nested drone
          // just because it has more scalar fields.
          resolvedDrone =
              _mergeDroneKeepingRealImage(
                base: resolvedDrone,
                full: fullDrone,
              );
        }
      } else if (dronesSuccess == false) {
        final value =
            _controller
                .applicantDronesErrorMessage
                ?.trim() ??
                '';

        if (value.isNotEmpty) {
          errorParts.add(value);
        }
      }

      CompanyContractModel? serverContract =
          _createdContract;

      String? contractLookupError;

      if (_application.isAccepted) {
        serverContract =
        contractFuture == null
            ? _createdContract
            : await contractFuture;

        contractLookupError =
            _contractController
                .existingContractErrorMessage;
      } else {
        serverContract = null;
        _contractController
            .clearApplicationContract();
      }

      if (!mounted) return;

      // Keep the shimmer until the important images are actually decoded.
      await _precacheCoreImages(
        job: freshJob ?? _job,
        pilot: resolvedPilot,
        drone: resolvedDrone,
      );

      if (!mounted) return;

      setState(() {
        if (freshJob != null) {
          _job = freshJob;
        }

        _pilot = resolvedPilot;
        _committedDrone = resolvedDrone;
        _credentials = resolvedCredentials;
        _createdContract = serverContract;
        _contractLookupLoading = false;
        _contractLookupError =
            contractLookupError;

        _application =
            _application.copyWith(
              pilotProfile: resolvedPilot,
              drone: resolvedDrone,
            );

        _backgroundError =
        errorParts.isEmpty
            ? null
            : 'Some applicant details could not be refreshed.';
      });

      unawaited(
        _saveCache(),
      );
    } finally {
      _backgroundRefreshing = false;
      _supportLoadedOnce = true;

      if (_contractLookupLoading &&
          !_application.isAccepted) {
        _contractLookupLoading = false;
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  CompanyApplicantDroneModel? _mergeDroneKeepingRealImage({
    required CompanyApplicantDroneModel? base,
    required CompanyApplicantDroneModel full,
  }) {
    if (base == null) {
      return full;
    }

    // If the dedicated drone endpoint has a real image, never lose it while
    // preserving the richer scalar details already returned by
    // /company/applicants.
    final image =
    full.imageUrl.trim().isNotEmpty
        ? full.imageUrl.trim()
        : base.imageUrl.trim();

    return CompanyApplicantDroneModel(
      id: full.id != 0 ? full.id : base.id,
      pilotProfileId:
      full.pilotProfileId ??
          base.pilotProfileId,
      make: full.make.trim().isNotEmpty
          ? full.make
          : base.make,
      model: full.model.trim().isNotEmpty
          ? full.model
          : base.model,
      manufactureYear:
      full.manufactureYear ??
          base.manufactureYear,
      serialNumber:
      full.serialNumber.trim().isNotEmpty
          ? full.serialNumber
          : base.serialNumber,
      weightKg:
      full.weightKg ??
          base.weightKg,
      capabilities:
      full.capabilities.isNotEmpty
          ? full.capabilities
          : base.capabilities,
      flightTimePerBatteryMinutes:
      full.flightTimePerBatteryMinutes ??
          base.flightTimePerBatteryMinutes,
      chargingTimeMinutes:
      full.chargingTimeMinutes ??
          base.chargingTimeMinutes,
      totalBatteries:
      full.totalBatteries ??
          base.totalBatteries,
      batteryType:
      full.batteryType.trim().isNotEmpty
          ? full.batteryType
          : base.batteryType,
      batteryUsageFee:
      full.batteryUsageFee ??
          base.batteryUsageFee,
      hourlyRate:
      full.hourlyRate ??
          base.hourlyRate,
      dailyRate:
      full.dailyRate ??
          base.dailyRate,
      emergencyCalloutFee:
      full.emergencyCalloutFee ??
          base.emergencyCalloutFee,
      imageUrl: image,
    );
  }

  CompanyApplicantDroneModel? _preferRicherDrone({
    required CompanyApplicantDroneModel? current,
    required CompanyApplicantDroneModel? incoming,
  }) {
    if (incoming == null) return current;
    if (current == null) return incoming;

    final currentScore = _droneRichness(current);
    final incomingScore = _droneRichness(incoming);
    return incomingScore >= currentScore ? incoming : current;
  }

  int _droneRichness(CompanyApplicantDroneModel drone) {
    var score = 0;
    if (drone.imageUrl.isNotEmpty) score += 4;
    if (drone.capabilities.isNotEmpty) score += 2;
    if (drone.flightTimePerBatteryMinutes != null) score++;
    if (drone.chargingTimeMinutes != null) score++;
    if (drone.batteryType.isNotEmpty) score++;
    if (drone.serialNumber.isNotEmpty) score++;
    return score;
  }

  // ==========================================================================
  // APPLICATION ACTIONS
  // ==========================================================================

  Future<void> _accept() async {
    if (!_application.isPending || _acting) return;

    final confirmed = await _confirmDialog(
      title: AppLanguage.text('Accept Applicant?'),
      message:
      'Accept ${_pilotName()} for this job? The application will move to Accepted.',
      confirmText: 'Accept',
      icon: Icons.check_circle_outline_rounded,
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.acceptApplicant(
      jobId: widget.jobId,
      application: _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      ),
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _showSnack(
        _controller.applicantsErrorMessage ??
            'Unable to accept applicant.',
        isError: true,
      );
      return;
    }

    setState(() {
      _application = updated.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );
      _changed = true;
    });

    unawaited(_saveCache());
    _showSnack('Applicant accepted successfully.');
  }

  Future<void> _reject() async {
    if (!_application.isPending || _acting) return;

    final reason = await _showRejectDialog();
    if (reason == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final updated = await _controller.rejectApplicant(
      jobId: widget.jobId,
      application: _application.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      ),
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );

    if (!mounted) return;

    if (updated == null) {
      setState(() {});
      _showSnack(
        _controller.applicantsErrorMessage ??
            'Unable to reject applicant.',
        isError: true,
      );
      return;
    }

    setState(() {
      _application = updated.copyWith(
        pilotProfile: _pilot,
        drone: _committedDrone,
      );
      _changed = true;
    });

    unawaited(_saveCache());
    _showSnack('Applicant rejected.');
  }

  Future<void> _openCreateContract() async {
    if (!_application.isAccepted ||
        _createdContract != null ||
        _openingContractScreen) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _openingContractScreen = true;
      _contractLookupLoading = true;
      _contractLookupError = null;
    });

    try {
      // Strong pre-flight guard: never open the Create Contract form until the
      // server confirms that this application/job has no existing contract.
      final contractJobId = _application.jobPostingId > 0
          ? _application.jobPostingId
          : widget.jobId;

      final existing = await _contractController.loadExistingContract(
        applicationId: _application.id,
        jobId: contractJobId,
      );

      if (!mounted) return;

      final lookupError = _contractController.existingContractErrorMessage;
      if (lookupError != null && lookupError.trim().isNotEmpty) {
        setState(() {
          _contractLookupLoading = false;
          _contractLookupError = lookupError;
        });
        _showSnack(
          'Couldn’t verify the current contract status. Please retry before creating a contract.',
          isError: true,
        );
        return;
      }

      if (existing != null) {
        setState(() {
          _createdContract = existing;
          _changed = true;
          _contractLookupLoading = false;
          _openingContractScreen = false;
        });
        unawaited(_saveCache());

        final belongsToThisApplication =
            existing.jobApplicationId == _application.id;
        _showSnack(
          belongsToThisApplication
              ? 'This application already has a contract. Opening it instead.'
              : 'This job already has an active contract. Opening the existing contract.',
        );

        await _openContractDetails();
        return;
      }

      setState(() => _contractLookupLoading = false);

      final contract = await Navigator.of(context).push<CompanyContractModel>(
        MaterialPageRoute(
          builder: (_) => CreateCompanyContractScreen(
            jobId: widget.jobId,
            application: _application.copyWith(
              pilotProfile: _pilot,
              drone: _committedDrone,
            ),
          ),
        ),
      );

      if (!mounted || contract == null) return;

      // The create screen returns either the newly-created contract or an
      // already-existing contract recovered after a backend duplicate guard.
      // In both cases the next screen is ALWAYS Contract Details.
      setState(() {
        _createdContract = contract;
        _contractController.applicationContract = contract;
        _changed = true;
        _openingContractScreen = false;
      });

      unawaited(_saveCache());

      if (contract.jobApplicationId == _application.id) {
        _showSnack('Contract ready. Opening contract details.');
      } else {
        _showSnack('Existing job contract found. Opening it instead.');
      }

      await _openContractDetails();
    } finally {
      if (mounted && _openingContractScreen) {
        setState(() {
          _openingContractScreen = false;
          _contractLookupLoading = false;
        });
      }
    }
  }

  Future<void> _openContractDetails() async {
    final contract = _createdContract;
    if (contract == null || _openingContractScreen) return;

    HapticFeedback.selectionClick();
    setState(() => _openingContractScreen = true);
    try {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CompanyContractDetailScreen(
            contractId: contract.id,
            initialContract: contract,
            initialJob: _job,
            initialApplication: _application.copyWith(
              pilotProfile: _pilot,
              drone: _committedDrone,
            ),
          ),
        ),
      );

      if (!mounted) return;
      if (changed == true) {
        try {
          final fresh = await _contractService.getContract(contract.id);
          if (!mounted) return;
          setState(() {
            _createdContract = fresh;
            _changed = true;
          });
          unawaited(_saveCache());
        } catch (_) {
          unawaited(_refreshInBackground());
        }
      }
    } finally {
      if (mounted) setState(() => _openingContractScreen = false);
    }
  }

  Future<void> _openAllContracts() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CompanyContractsScreen(),
      ),
    );
    if (mounted) unawaited(_refreshInBackground());
  }

  Future<void> _retryContractLookup() async {
    if (_contractLookupLoading) return;

    setState(() {
      _contractLookupLoading = true;
      _contractLookupError = null;
    });

    final contractJobId = _application.jobPostingId > 0
        ? _application.jobPostingId
        : widget.jobId;

    final contract = await _contractController.loadExistingContract(
      applicationId: _application.id,
      jobId: contractJobId,
    );

    if (!mounted) return;

    setState(() {
      _createdContract = contract;
      _contractLookupError =
          _contractController.existingContractErrorMessage;
      _contractLookupLoading = false;
    });

    if (_contractLookupError == null) {
      unawaited(_saveCache());
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12.2,
              height: 1.45,
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
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectDialog() async {
    String draftReason = '';

    return showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(AppLanguage.text('Reject Applicant?'),
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLanguage.text('You can add a rejection reason or leave it empty.'),
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => draftReason = value,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: AppLanguage.text('Optional rejection reason...'),
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
              child: Text(AppLanguage.text('Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftReason.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(AppLanguage.text('Reject')),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // PRIVATE DOCUMENT PREVIEW
  // ==========================================================================

  Future<void> _openDocument(CompanyPilotMediaModel document) async {
    if (_openingMediaId != null) return;

    HapticFeedback.selectionClick();
    setState(() => _openingMediaId = document.id);

    try {
      final path = await _controller.downloadApplicantDocument(
        document: document,
      );

      if (!mounted) return;

      if (path == null || path.trim().isEmpty) {
        _showSnack(
          _controller.applicantDocumentErrorMessage ??
              'Unable to open this document.',
          isError: true,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompanyDocumentViewerScreen(
            filePath: path,
            fileName: document.fileName.trim().isEmpty
                ? 'document_${document.id}'
                : document.fileName.trim(),
            mimeType: document.mimeType,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingMediaId = null);
      }
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final initialReady =
        _cacheReadFinished &&
            _supportLoadedOnce;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFC),
        body: SafeArea(
          child: !initialReady
              ? const _ApplicantDetailShimmer()
              : Column(
            children: [
              _referenceTopBar(),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF10A9B9),
                  backgroundColor: Colors.white,
                  onRefresh: _refreshInBackground,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    children: [
                      _referenceApplicantHero(),
                      if (_backgroundError != null) ...[
                        const SizedBox(height: 8),
                        _OfflineNotice(
                          message: _backgroundError!,
                          onRetry: _refreshInBackground,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _referenceTabs(),
                      const SizedBox(height: 10),
                      _referenceTabContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
        initialReady && _application.isPending
            ? _referenceBottomActions()
            : null,
      ),
    );
  }


  Widget _referenceTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 7, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(_changed),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: Color(0xFF0A2D46),
            ),
          ),
          const Expanded(
            child: Text(
              'Applicant Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0A2D46),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -.15,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF0A2D46),
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'refresh') {
                unawaited(_refreshInBackground());
              } else if (value == 'contracts') {
                unawaited(_openAllContracts());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text(
                  'Refresh',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (_application.isAccepted)
                const PopupMenuItem(
                  value: 'contracts',
                  child: Text(
                    'All contracts',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceApplicantHero() {
    final pilot = _pilot;
    final name = _pilotName();
    final visual = _applicationVisual(_application.status);

    final location = pilot?.location.trim() ?? '';
    final experience = pilot?.experienceLabel.trim() ?? '';
    final nationality = pilot?.nationality.trim() ?? '';

    final summaryParts = <String>[
      if (experience.isNotEmpty) experience,
      if (nationality.isNotEmpty) nationality,
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6F0F3),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: pilot?.profilePhoto.trim().isNotEmpty == true
                      ? Image.network(
                    pilot!.profilePhoto.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _referencePilotFallback(name),
                  )
                      : _referencePilotFallback(name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0A2D46),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (pilot?.verified == true) ...[
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF10A99B),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ReferenceApplicantStatusPill(
                            label: _application.statusLabel,
                            foreground: visual.foreground,
                            background: visual.background,
                          ),
                        ],
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF607789),
                            fontSize: 11.3,
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (summaryParts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          summaryParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF607789),
                            fontSize: 11.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5F5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 15,
                  color: Color(0xFF0B9CAE),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application #${_application.id}',
                      style: const TextStyle(
                        color: Color(0xFF0A2D46),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applied ${_formatDateTime(_application.createdAt)}',
                      style: const TextStyle(
                        color: Color(0xFF708596),
                        fontSize: 10.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF7C8E9B),
              ),
            ],
          ),
        ),
      ],
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
            Color(0xFF5FB9C3),
            Color(0xFF2D7586),
          ],
        ),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _referenceTabs() {
    const labels = ['Proposal', 'Pilot', 'Equipment', 'Documents'];

    return Row(
      children: List.generate(labels.length, (index) {
        final selected = _referenceTab == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == labels.length - 1 ? 0 : 6,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _referenceTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  height: 37,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: [
                        Color(0xFF13B4C3),
                        Color(0xFF0798B3),
                      ],
                    )
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF0B9EB4)
                          : const Color(0xFFDDE8EC),
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF0AA4B8)
                            .withOpacity(.12),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                      selected ? Colors.white : const Color(0xFF0A2D46),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _referenceTabContent() {
    switch (_referenceTab) {
      case 1:
        return _referencePilotTab();
      case 2:
        return _referenceEquipmentTab();
      case 3:
        return _referenceDocumentsTab();
      default:
        return _referenceProposalTab();
    }
  }

  Widget _referenceProposalTab() {
    return Column(
      children: [
        _referenceJobProposalCard(),
        const SizedBox(height: 10),
        _referencePilotSummaryCard(),
        const SizedBox(height: 10),
        _referenceSelectedEquipmentCard(),
        if (_application.isAccepted) ...[
          const SizedBox(height: 10),
          _referenceAcceptedContractCard(),
        ],
      ],
    );
  }

  Widget _referenceJobProposalCard() {
    final job = _job;
    final title = job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Job';
    final location = _referenceJobLocation(job);
    final jobImage = _referenceJobImage(job);
    final cover = _application.coverMessage.trim();

    return _ReferenceApplicantCard(
      title: 'Job & Proposal',
      icon: Icons.work_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: jobImage.isNotEmpty
                    ? Image.network(
                  jobImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const _ReferenceJobFallback(),
                )
                    : const _ReferenceJobFallback(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0A2D46),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Color(0xFF0B9EAF),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7F8D),
                                fontSize: 10.3,
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
          const SizedBox(height: 10),
          _referenceProposalPilot(),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cover.isEmpty
                  ? 'No cover message was submitted with this application.'
                  : cover,
              style: const TextStyle(
                color: Color(0xFF526A7B),
                fontSize: 10.8,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReferenceProposalStat(
                  icon: Icons.payments_outlined,
                  label: 'Job budget',
                  value: _referenceJobPayment(job),
                  helper: job == null || job.paymentType.trim().isEmpty
                      ? ''
                      : _pretty(job.paymentType),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReferenceProposalStat(
                  icon: Icons.calendar_month_outlined,
                  label: 'Job dates',
                  value: _referenceJobDates(job),
                  helper: 'Application submitted ${_formatDate(_application.createdAt)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referenceProposalPilot() {
    final pilot = _pilot;

    if (pilot == null) {
      return const _InlineLoadError(
        icon: Icons.person_outline_rounded,
        text: 'Pilot information could not be loaded.',
      );
    }

    final name = pilot.displayName.trim();
    final location = pilot.location.trim();
    final experience = pilot.experienceLabel.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0EAED),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F0F3),
            ),
            child: ClipOval(
              child: pilot.profilePhoto.trim().isNotEmpty
                  ? Image.network(
                pilot.profilePhoto.trim(),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    _referencePilotFallback(name),
              )
                  : _referencePilotFallback(name),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proposal from',
                  style: TextStyle(
                    color: Color(0xFF81929F),
                    fontSize: 9.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? 'Pilot' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 11.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (location.isNotEmpty || experience.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (experience.isNotEmpty) experience,
                      if (location.isNotEmpty) location,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF687E8E),
                      fontSize: 9.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (pilot.verified==true)
            const Icon(
              Icons.verified_rounded,
              size: 14,
              color: Color(0xFF10A99B),
            ),
        ],
      ),
    );
  }

  Widget _referencePilotSummaryCard() {
    final pilot = _pilot;

    if (pilot == null) {
      return const _ReferenceApplicantCard(
        title: 'Pilot Summary',
        icon: Icons.person_outline_rounded,
        child: Text(
          'Pilot profile is loading...',
          style: TextStyle(
            color: Color(0xFF708596),
            fontSize: 11,
          ),
        ),
      );
    }

    final location = pilot.location.trim();

    return _ReferenceApplicantCard(
      title: 'Pilot Summary',
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE7F0F2),
                ),
                child: ClipOval(
                  child: pilot.profilePhoto.trim().isNotEmpty
                      ? Image.network(
                    pilot.profilePhoto.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _referencePilotFallback(pilot.displayName),
                  )
                      : _referencePilotFallback(pilot.displayName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilot.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0A2D46),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (pilot.experienceLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        pilot.experienceLabel,
                        style: const TextStyle(
                          color: Color(0xFF687E8E),
                          fontSize: 10.4,
                        ),
                      ),
                    ],
                    if (pilot.nationality.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        pilot.nationality.trim(),
                        style: const TextStyle(
                          color: Color(0xFF687E8E),
                          fontSize: 10.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (location.isNotEmpty)
                Container(
                  width: 118,
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFFE2EAED)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: Color(0xFF8A9AA6),
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0A2D46),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (pilot.languages.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Languages',
              style: TextStyle(
                color: Color(0xFF0A2D46),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pilot.languages.take(6).map((language) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    language,
                    style: const TextStyle(
                      color: Color(0xFF0B95A6),
                      fontSize: 9.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _referenceSelectedEquipmentCard() {
    final drone = _committedDrone;

    return _ReferenceApplicantCard(
      title: 'Selected Equipment',
      icon: Icons.precision_manufacturing_outlined,
      child: drone == null
          ? const _ReferenceEquipmentUnavailable()
          : Row(
        children: [
          _ReferenceDronePhoto(
            imageUrl: drone.imageUrl.trim(),
            width: 82,
            height: 54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  drone.capabilities.isEmpty
                      ? 'Equipment details loaded'
                      : drone.capabilities
                      .take(3)
                      .map(_pretty)
                      .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF687E8E),
                    fontSize: 10.1,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF718595),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _referencePilotTab() {
    final pilot = _pilot;

    if (pilot == null) {
      return const _ReferenceApplicantCard(
        title: 'Pilot',
        icon: Icons.person_outline_rounded,
        child: Text(
          'Pilot profile is loading...',
          style: TextStyle(
            color: Color(0xFF708596),
            fontSize: 11,
          ),
        ),
      );
    }

    return Column(
      children: [
        _referencePilotSummaryCard(),
        const SizedBox(height: 10),
        _ReferenceApplicantCard(
          title: 'Pilot Profile',
          icon: Icons.person_search_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _referenceKeyValue(
                'Location',
                pilot.location.isEmpty ? '—' : pilot.location,
              ),
              _referenceKeyValue(
                'Experience',
                pilot.experienceLabel.isEmpty
                    ? '—'
                    : pilot.experienceLabel,
              ),
              if (pilot.nationality.isNotEmpty)
                _referenceKeyValue('Nationality', pilot.nationality),
              if (pilot.previousCompany.isNotEmpty)
                _referenceKeyValue(
                  'Previous company',
                  pilot.previousCompany,
                ),
              if (pilot.bio.isNotEmpty) ...[
                const SizedBox(height: 7),
                const Text(
                  'About',
                  style: TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 10.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pilot.bio,
                  style: const TextStyle(
                    color: Color(0xFF526A7B),
                    fontSize: 10.6,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _referenceEquipmentTab() {
    final drone = _committedDrone;

    if (drone == null) {
      return const _ReferenceApplicantCard(
        title: 'Equipment',
        icon: Icons.flight_outlined,
        child: _ReferenceEquipmentUnavailable(),
      );
    }

    return Column(
      children: [
        _referenceSelectedEquipmentCard(),
        const SizedBox(height: 10),
        _ReferenceApplicantCard(
          title: 'Drone Details',
          icon: Icons.flight_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (drone.manufactureYear != null)
                _referenceKeyValue(
                  'Year',
                  '${drone.manufactureYear}',
                ),
              if (drone.serialNumber.isNotEmpty)
                _referenceKeyValue('Serial', drone.serialNumber),
              if (drone.weightKg != null)
                _referenceKeyValue(
                  'Weight',
                  '${_cleanNumber(drone.weightKg!)} kg',
                ),
              if (drone.flightTimePerBatteryMinutes != null)
                _referenceKeyValue(
                  'Flight time',
                  '${drone.flightTimePerBatteryMinutes} min / battery',
                ),
              if (drone.chargingTimeMinutes != null)
                _referenceKeyValue(
                  'Charging',
                  '${drone.chargingTimeMinutes} min',
                ),
              if (drone.totalBatteries != null)
                _referenceKeyValue(
                  'Batteries',
                  '${drone.totalBatteries}',
                ),
              if (drone.capabilities.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: drone.capabilities.map((value) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _pretty(value),
                        style: const TextStyle(
                          color: Color(0xFF0B95A6),
                          fontSize: 9.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _referenceDocumentsTab() {
    if (_credentials.isEmpty) {
      return const _ReferenceApplicantCard(
        title: 'Documents',
        icon: Icons.folder_open_outlined,
        child: _EmptyInlineState(
          icon: Icons.badge_outlined,
          text: 'No pilot credentials were returned.',
        ),
      );
    }

    return _ReferenceApplicantCard(
      title: 'Documents',
      icon: Icons.folder_open_outlined,
      child: Column(
        children: List.generate(_credentials.length, (index) {
          final credential = _credentials[index];
          final type = credential.licenseType.trim().isEmpty
              ? 'Credential #${credential.id}'
              : _pretty(credential.licenseType);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _credentials.length - 1 ? 0 : 9,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE1EAED),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: credential.isExpired
                              ? const Color(0xFFFFECEA)
                              : const Color(0xFFE8F8F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          size: 17,
                          color: credential.isExpired
                              ? const Color(0xFFE6574F)
                              : const Color(0xFF10A889),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0A2D46),
                                fontSize: 11.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              credential.isExpired
                                  ? 'Expired'
                                  : credential.expiresAt == null
                                  ? 'Expiration not provided'
                                  : 'Valid until ${_formatDate(credential.expiresAt)}',
                              style: TextStyle(
                                color: credential.isExpired
                                    ? const Color(0xFFE6574F)
                                    : const Color(0xFF718595),
                                fontSize: 9.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (credential.media.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: credential.media
                          .map(_documentButton)
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _referenceAcceptedContractCard() {
    final contract = _createdContract;

    if (_contractLookupLoading && contract == null) {
      return const _ReferenceApplicantCard(
        title: 'Contract',
        icon: Icons.description_outlined,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0B9EAF),
              ),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Checking the latest contract status...',
                style: TextStyle(
                  color: Color(0xFF607789),
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (contract == null) {
      return _ReferenceApplicantCard(
        title: 'Accepted Application',
        icon: Icons.handshake_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This pilot has been accepted. Create the contract to continue.',
              style: TextStyle(
                color: Color(0xFF526A7B),
                fontSize: 10.7,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: FilledButton.icon(
                onPressed:
                _openingContractScreen ? null : _openCreateContract,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0CA6B7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(
                  Icons.description_outlined,
                  size: 16,
                ),
                label: const Text(
                  'Create Contract',
                  style: TextStyle(
                    fontSize: 11.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _ReferenceApplicantCard(
      title: 'Contract',
      icon: Icons.description_outlined,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contract #${contract.id}',
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contract.statusLabel,
                  style: const TextStyle(
                    color: Color(0xFF6C8191),
                    fontSize: 10.2,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed:
            _openingContractScreen ? null : _openContractDetails,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B9EAF),
              side: const BorderSide(
                color: Color(0xFFBBDDE1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceKeyValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF81929E),
                fontSize: 10.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0A2D46),
                fontSize: 10.6,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _referenceJobLocation(CompanyJobPostingModel? job) {
    if (job == null) return '';

    final parts = <String>[
      job.city,
      job.state,
      job.country,
    ].where((value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(', ');

    return job.region.trim();
  }

  String _referenceJobPayment(CompanyJobPostingModel? job) {
    if (job == null) return '—';

    String money(double? value) {
      if (value == null) return '';
      final clean = value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);
      return '\$$clean';
    }

    final min = money(job.paymentMin);
    final max = money(job.paymentMax);

    if (min.isNotEmpty && max.isNotEmpty) {
      return '$min – $max';
    }
    if (min.isNotEmpty) return min;
    if (max.isNotEmpty) return max;
    return 'Not specified';
  }

  String _referenceJobDates(CompanyJobPostingModel? job) {
    if (job == null) return '—';

    final start = _formatDate(job.startDate);
    final end = _formatDate(job.endDate);

    if (job.startDate != null && job.endDate != null) {
      return '$start → $end';
    }
    if (job.startDate != null) return start;
    if (job.endDate != null) return end;
    return 'Not specified';
  }

  String _referenceJobImage(CompanyJobPostingModel? job) {
    if (job == null) return '';

    String clean(dynamic value) => value?.toString().trim() ?? '';

    try {
      final value = clean((job as dynamic).imageUrl);
      if (value.isNotEmpty) return value;
    } catch (_) {}

    try {
      final value = clean((job as dynamic).image);
      if (value.isNotEmpty) return value;
    } catch (_) {}

    try {
      final attachments = (job as dynamic).attachments;
      for (final attachment in attachments) {
        try {
          final url = clean(attachment.url);
          final lower = '${attachment.name} $url'.toLowerCase();
          if (lower.contains('.png') ||
              lower.contains('.jpg') ||
              lower.contains('.jpeg') ||
              lower.contains('.webp')) {
            return url;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return '';
  }

  Widget _referenceBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE1EAED)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A2D46).withOpacity(.05),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE85B52),
                    side: const BorderSide(
                      color: Color(0xFFEF766D),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF13B5C4),
                        Color(0xFF0798B3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0AA4B9)
                            .withOpacity(.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _acting ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Accept pilot',
                      style: TextStyle(
                        fontSize: 11.2,
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 5),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(_changed),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(AppLanguage.text('Applicant Details'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: _backgroundRefreshing || _supportLoading
                ? const Center(child: _TinyPulse())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final visual = _applicationVisual(_application.status);
    final name = _pilotName();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A3A),
            Color(0xFF0D4757),
            Color(0xFF0D8AA5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.12),
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
              _StatusBadge(
                label: _application.statusLabel,
                foreground: visual.foreground,
                background: visual.background,
              ),
              const Spacer(),
              Text(
                '#${_application.id}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.10),
                  foregroundImage:
                  _pilot?.profilePhoto.trim().isNotEmpty == true
                      ? NetworkImage(_pilot!.profilePhoto.trim())
                      : null,
                  child: _pilot?.profilePhoto.trim().isNotEmpty == true
                      ? null
                      : Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_pilot?.verified == true) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF7BE4D8),
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _pilotHeroSubtitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 11.4,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Application for Job #${_application.jobPostingId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_backgroundRefreshing) const _HeroSyncBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationInfo() {
    return _section(
      title: AppLanguage.text('Application'),
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: AppLanguage.text('Application'),
                  value: '#${_application.id}',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  label: AppLanguage.text('Job'),
                  value: '#${_application.jobPostingId}',
                  icon: Icons.work_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            'Submitted',
            _formatDateTime(_application.createdAt),
            Icons.schedule_rounded,
          ),
          if (_application.decidedAt != null)
            _infoRow(
              'Decision',
              _formatDateTime(_application.decidedAt),
              Icons.fact_check_outlined,
            ),
          if (_application.withdrawnAt != null)
            _infoRow(
              'Withdrawn',
              _formatDateTime(_application.withdrawnAt),
              Icons.undo_rounded,
            ),
        ],
      ),
    );
  }

  Widget _pilotSection() {
    final pilot = _pilot;

    if (pilot == null) {
      if (_supportLoading || _backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 4),
        );
      }

      return _section(
        title: AppLanguage.text('Pilot Profile'),
        icon: Icons.person_outline_rounded,
        child: Text(
          'Pilot #${_application.pilotProfileId}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _section(
      title: AppLanguage.text('Pilot Profile'),
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: AppLanguage.text('Location'),
                  value: pilot.location.isEmpty ? '—' : pilot.location,
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MiniStat(
                  label: AppLanguage.text('Experience'),
                  value: pilot.experienceLabel.isEmpty
                      ? '—'
                      : pilot.experienceLabel,
                  icon: Icons.timeline_rounded,
                ),
              ),
            ],
          ),
          if (pilot.dateOfBirth != null) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Date of birth',
              _formatDate(pilot.dateOfBirth),
              Icons.cake_outlined,
            ),
          ],
          if (pilot.nationality.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Nationality',
              pilot.nationality,
              Icons.public_rounded,
            ),
          ],
          if (pilot.languages.isNotEmpty) ...[
            const SizedBox(height: 6),
            const _SubLabel('Languages'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.languages.map(_chip).toList(),
            ),
          ],
          if (pilot.bio.isNotEmpty) ...[
            const SizedBox(height: 13),
            const _SubLabel('About'),
            const SizedBox(height: 6),
            Text(
              pilot.bio,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12.2,
                height: 1.5,
              ),
            ),
          ],
          if (pilot.previousCompany.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Previous',
              pilot.previousCompany,
              Icons.business_center_outlined,
            ),
          ],
          if (pilot.linkedinUrl.isNotEmpty) ...[
            _infoRow(
              'LinkedIn',
              pilot.linkedinUrl,
              Icons.link_rounded,
            ),
          ],
          if (pilot.workRegions.isNotEmpty) ...[
            const SizedBox(height: 6),
            const _SubLabel('Available work regions'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.workRegions
                  .where((region) => region.label.isNotEmpty)
                  .take(6)
                  .map((region) => _chip(region.label))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _credentialsSection() {
    if (_credentials.isEmpty &&
        (!_supportLoadedOnce || _supportLoading || _backgroundRefreshing)) {
      return const _ShimmerAnimator(
        child: _CredentialSectionShimmer(),
      );
    }

    return _section(
      title: AppLanguage.text('Credentials & Documents'),
      icon: Icons.workspace_premium_outlined,
      child: _credentials.isEmpty
          ? const _EmptyInlineState(
        icon: Icons.badge_outlined,
        text: 'No pilot credentials were returned.',
      )
          : Column(
        children: List.generate(
          _credentials.length,
              (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == _credentials.length - 1 ? 0 : 10,
            ),
            child: _credentialCard(_credentials[index]),
          ),
        ),
      ),
    );
  }

  Widget _credentialCard(CompanyPilotCredentialModel credential) {
    final type = credential.licenseType.trim().isEmpty
        ? 'Credential #${credential.id}'
        : _pretty(credential.licenseType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: credential.isExpired
                      ? AppColors.redBg
                      : AppColors.greenBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: credential.isExpired
                      ? AppColors.red
                      : AppColors.green,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      credential.isExpired
                          ? 'Expired'
                          : credential.expiresAt == null
                          ? 'Expiration not provided'
                          : 'Valid until ${_formatDate(credential.expiresAt)}',
                      style: TextStyle(
                        color: credential.isExpired
                            ? AppColors.red
                            : AppColors.grey,
                        fontSize: 10.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (credential.licenseNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _compactInfoRow(
              'License number',
              credential.licenseNumber,
            ),
          ],
          if (credential.issuingAuthority.isNotEmpty)
            _compactInfoRow(
              'Authority',
              _pretty(credential.issuingAuthority),
            ),
          if (credential.expiresAt != null)
            _compactInfoRow(
              'Expires',
              _formatDate(credential.expiresAt),
            ),
          if (credential.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: credential.media.map(_documentButton).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _documentButton(CompanyPilotMediaModel document) {
    final busy = _openingMediaId == document.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: _openingMediaId != null
            ? null
            : () => _openDocument(document),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const _TinyPulse()
              else
                Icon(
                  document.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: AppColors.blue,
                  size: 15,
                ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  document.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _droneSection() {
    final drone = _committedDrone;

    if (drone == null) {
      if (_supportLoading || _backgroundRefreshing) {
        return const _ShimmerAnimator(
          child: _DetailSectionShimmer(rows: 5),
        );
      }

      return _section(
        title: AppLanguage.text('Committed Drone'),
        icon: Icons.flight_outlined,
        child: const _ReferenceEquipmentUnavailable(),
      );
    }

    return _section(
      title: AppLanguage.text('Committed Drone'),
      icon: Icons.flight_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.greenBg,
                  AppColors.greenBg.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _ReferenceDronePhoto(
                  imageUrl: drone.imageUrl.trim(),
                  width: 62,
                  height: 54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (drone.manufactureYear != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${drone.manufactureYear}',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              ],
            ),
          ),
          if (drone.capabilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: drone.capabilities
                  .map((value) => _chip(_pretty(value)))
                  .toList(),
            ),
          ],
          if (drone.serialNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              'Serial',
              drone.serialNumber,
              Icons.numbers_rounded,
            ),
          ],
          if (drone.weightKg != null)
            _infoRow(
              'Weight',
              '${_cleanNumber(drone.weightKg!)} kg',
              Icons.monitor_weight_outlined,
            ),
          if (drone.flightTimePerBatteryMinutes != null)
            _infoRow(
              'Flight time',
              '${drone.flightTimePerBatteryMinutes} min/battery',
              Icons.timer_outlined,
            ),
          if (drone.chargingTimeMinutes != null)
            _infoRow(
              'Charging',
              '${drone.chargingTimeMinutes} min',
              Icons.battery_charging_full_rounded,
            ),
          if (drone.totalBatteries != null)
            _infoRow(
              'Batteries',
              '${drone.totalBatteries}',
              Icons.battery_6_bar_rounded,
            ),
          if (drone.batteryType.isNotEmpty)
            _infoRow(
              'Battery type',
              drone.batteryType,
              Icons.battery_saver_outlined,
            ),
        ],
      ),
    );
  }

  Widget _acceptedStateCard() {
    final contract = _createdContract;
    final belongsToThisApplication =
        contract == null || contract.jobApplicationId == _application.id;

    if (_contractLookupLoading && contract == null) {
      return _section(
        title: AppLanguage.text('Contract'),
        icon: Icons.description_outlined,
        accent: AppColors.blue,
        accentBackground: AppColors.blueBg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.blueBg.withOpacity(0.58),
            borderRadius: BorderRadius.circular(14),
          ),
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
                  'Checking the latest contract status from the server...',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.2,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_contractLookupError != null && contract == null) {
      return _section(
        title: AppLanguage.text('Contract'),
        icon: Icons.cloud_off_outlined,
        accent: AppColors.orange,
        accentBackground: AppColors.orangeBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _contractLookupError!,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _retryContractLookup,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry Contract Check'),
            ),
          ],
        ),
      );
    }

    return _section(
      title: AppLanguage.text(
        contract == null
            ? 'Accepted Application'
            : belongsToThisApplication
            ? 'Contract'
            : 'Existing Job Contract',
      ),
      icon: contract == null
          ? Icons.handshake_outlined
          : Icons.description_outlined,
      accent: AppColors.green,
      accentBackground: AppColors.greenBg,
      child: contract == null
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.greenBg.withOpacity(0.62),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This pilot has been selected. Create the contract to continue Phase 3.',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 11.2,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openingContractScreen
                  ? null
                  : _openCreateContract,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: _openingContractScreen
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.description_outlined, size: 18),
              label: Text(
                AppLanguage.text('Create Contract'),
                style: const TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      )
          : Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: contract.isAccepted
              ? AppColors.greenBg.withOpacity(0.72)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: contract.isAccepted
                ? AppColors.green.withOpacity(0.14)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: contract.isAccepted
                        ? Colors.white
                        : AppColors.blueBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    contract.isAccepted
                        ? Icons.account_balance_wallet_rounded
                        : Icons.description_outlined,
                    color: contract.isAccepted
                        ? AppColors.green
                        : AppColors.blue,
                    size: 19,
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
                          fontSize: 12.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        !belongsToThisApplication
                            ? 'This job already has a contract for another application'
                            : contract.isAccepted
                            ? 'Pilot accepted • Ready to fund'
                            : contract.isPending
                            ? 'Waiting for pilot response'
                            : contract.statusLabel,
                        style: TextStyle(
                          color: contract.isAccepted
                              ? AppColors.green
                              : AppColors.grey,
                          fontSize: 10.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: contract.isAccepted
                        ? Colors.white
                        : AppColors.blueBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contract.statusLabel,
                    style: TextStyle(
                      color: contract.isAccepted
                          ? AppColors.green
                          : AppColors.blue,
                      fontSize: 9.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _compactInfoRow('Amount', contract.amountLabel),
            _compactInfoRow('Payment', contract.paymentTypeLabel),
            _compactInfoRow('Start', _formatDate(contract.startDate)),
            if (contract.endDate != null)
              _compactInfoRow('End', _formatDate(contract.endDate)),
            const SizedBox(height: 11),
            FilledButton.icon(
              onPressed: _openingContractScreen
                  ? null
                  : _openContractDetails,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor:
                contract.isAccepted && belongsToThisApplication
                    ? AppColors.green
                    : AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(
                contract.isAccepted && belongsToThisApplication
                    ? Icons.account_balance_wallet_rounded
                    : Icons.open_in_new_rounded,
                size: 18,
              ),
              label: Text(
                contract.isAccepted && belongsToThisApplication
                    ? 'Open & Fund Contract'
                    : !belongsToThisApplication
                    ? 'Open Existing Contract'
                    : 'View Contract',
                style: const TextStyle(
                  fontSize: 12.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openAllContracts,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.list_alt_rounded, size: 17),
              label: const Text(
                'All Contracts',
                style: TextStyle(
                  fontSize: 11.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SHARED UI
  // ==========================================================================

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Color accent = AppColors.blue,
    Color accentBackground = AppColors.blueBg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.022),
            blurRadius: 18,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 15,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11.6,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 10.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_acting) ...[
              const _ActionLoadingBar(),
              const SizedBox(height: 9),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _acting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    label: Text(AppLanguage.text('Reject'),
                      style: TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _acting ? null : _accept,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(AppLanguage.text('Accept'),
                      style: TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  String _pilotName() {
    final pilot = _pilot;
    if (pilot != null && pilot.name.trim().isNotEmpty) {
      return pilot.name.trim();
    }
    return 'Pilot #${_application.pilotProfileId}';
  }

  String _pilotHeroSubtitle() {
    final pilot = _pilot;
    if (pilot == null) {
      return 'Pilot profile #${_application.pilotProfileId}';
    }

    final parts = <String>[];
    if (pilot.location.isNotEmpty) parts.add(pilot.location);
    if (pilot.experienceLabel.isNotEmpty) {
      parts.add(pilot.experienceLabel);
    }

    return parts.isEmpty
        ? 'Pilot profile #${pilot.id}'
        : parts.join(' · ');
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

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _cleanNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? Colors.red.shade700 : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            message,
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
      );
  }
}


class _ReferenceDronePhoto extends StatelessWidget {
  const _ReferenceDronePhoto({
    required this.imageUrl,
    this.width = 82,
    this.height = 54,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE0E9EC),
        ),
      ),
      child: url.isEmpty
          ? const _ReferenceDroneFallback()
          : Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _ReferenceDroneImageShimmer();
        },
        errorBuilder: (_, __, ___) =>
        const _ReferenceDroneFallback(),
      ),
    );
  }
}

class _ReferenceDroneFallback extends StatelessWidget {
  const _ReferenceDroneFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F7F8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.flight_rounded,
        color: Color(0xFF0B9EAF),
        size: 25,
      ),
    );
  }
}

class _ReferenceDroneImageShimmer extends StatelessWidget {
  const _ReferenceDroneImageShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE8EFF1),
          ),
        ),
      ),
    );
  }
}

class _ReferenceEquipmentUnavailable extends StatelessWidget {
  const _ReferenceEquipmentUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ReferenceDronePhoto(
          imageUrl: '',
          width: 82,
          height: 54,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Equipment details are unavailable.',
            style: TextStyle(
              color: Color(0xFF687E8E),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0B9EAF),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF687E8E),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceApplicantCard extends StatelessWidget {
  const _ReferenceApplicantCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE0E9EC),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.018),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8F7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: const Color(0xFF0B9EAF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ReferenceApplicantStatusPill extends StatelessWidget {
  const _ReferenceApplicantStatusPill({
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReferenceProposalStat extends StatelessWidget {
  const _ReferenceProposalStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3EAED),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0B9EAF),
              size: 15,
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
                    color: Color(0xFF81919C),
                    fontSize: 9.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (helper.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718595),
                      fontSize: 9.2,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceJobFallback extends StatelessWidget {
  const _ReferenceJobFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF90C7CC),
            Color(0xFF4B8290),
          ],
        ),
      ),
      child: const Icon(
        Icons.landscape_outlined,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 15,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11.7,
              fontWeight: FontWeight.w800,
              height: 1.25,
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
        horizontal: 10,
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
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.grey,
        fontSize: 10.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  const _EmptyInlineState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.grey,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSyncBadge extends StatelessWidget {
  const _HeroSyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const _TinyPulse(),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLanguage.text('Retry'),
              style: TextStyle(fontSize: 10.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantBackground extends StatelessWidget {
  const _ApplicantBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
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
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.green.withOpacity(0.05),
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

class _ApplicantDetailShimmer extends StatelessWidget {
  const _ApplicantDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerAnimator(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 58, 16, 26),
        child: Column(
          children: [
            _ApplicantHeroShimmer(),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 3),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 5),
            SizedBox(height: 12),
            _CredentialSectionShimmer(),
            SizedBox(height: 12),
            _DetailSectionShimmer(rows: 5),
          ],
        ),
      ),
    );
  }
}

class _ApplicantHeroShimmer extends StatelessWidget {
  const _ApplicantHeroShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 76, height: 25, radius: 20),
              Spacer(),
              _ShimmerBox(width: 30, height: 13, radius: 6),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _ShimmerBox(width: 60, height: 60, radius: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 150, height: 16, radius: 7),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 210, height: 11, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _ShimmerBox(width: double.infinity, height: 40, radius: 14),
        ],
      ),
    );
  }
}

class _DetailSectionShimmer extends StatelessWidget {
  const _DetailSectionShimmer({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ShimmerBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 9),
              _ShimmerBox(width: 126, height: 15, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            rows,
                (index) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _ShimmerBox(
                width: double.infinity,
                height: 13,
                radius: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialSectionShimmer extends StatelessWidget {
  const _CredentialSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              _ShimmerBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 9),
              _ShimmerBox(width: 170, height: 15, radius: 6),
            ],
          ),
          SizedBox(height: 14),
          _ShimmerBox(width: double.infinity, height: 122, radius: 15),
          SizedBox(height: 9),
          _ShimmerBox(width: double.infinity, height: 122, radius: 15),
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
      duration: const Duration(milliseconds: 1250),
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
        final value = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.4 + (value * 2.8), 0),
              end: Alignment(-0.4 + (value * 2.8), 0),
              colors: const [
                Color(0xFFEAF0F4),
                Color(0xFFF8FBFC),
                Color(0xFFEAF0F4),
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F4),
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
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.35,
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
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionLoadingBar extends StatefulWidget {
  const _ActionLoadingBar();

  @override
  State<_ActionLoadingBar> createState() => _ActionLoadingBarState();
}

class _ActionLoadingBarState extends State<_ActionLoadingBar>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0,
                0.25 + (_controller.value * 0.35),
                1,
              ],
              colors: [
                AppColors.blueBg,
                AppColors.blue,
                AppColors.blueBg,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisualPair {
  const _VisualPair({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

_VisualPair _applicationVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        foreground: AppColors.green,
        background: AppColors.greenBg,
      );
    case 'rejected':
      return const _VisualPair(
        foreground: AppColors.red,
        background: AppColors.redBg,
      );
    case 'withdrawn':
      return const _VisualPair(
        foreground: AppColors.orange,
        background: AppColors.orangeBg,
      );
    default:
      return const _VisualPair(
        foreground: Color(0xFFE9872F),
        background: Color(0xFFFFF0E0),
      );
  }
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
      .toList();

  if (parts.isEmpty) return 'P#';
  if (parts.length == 1) {
    final text = parts.first;
    return text.length <= 2
        ? text.toUpperCase()
        : text.substring(0, 2).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
