import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_application_model.dart';
import '../../services/company_job_service.dart';

class CompanyApplicantDetailScreen
    extends StatefulWidget {
  const CompanyApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.application,
  });

  final int jobId;
  final CompanyJobApplicationModel application;

  @override
  State<CompanyApplicantDetailScreen>
      createState() =>
          _CompanyApplicantDetailScreenState();
}

class _CompanyApplicantDetailScreenState
    extends State<CompanyApplicantDetailScreen> {
  late final CompanyJobController _controller;
  late CompanyJobApplicationModel _application;

  bool _changed = false;

  bool get _acting =>
      _controller.isAcceptingApplicant ||
      _controller.isRejectingApplicant;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _application = widget.application;
  }

  Future<void> _accept() async {
    if (!_application.isPending || _acting) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Accept Applicant?'),
          content: Text(
            'Accept ${_pilotName()} for this job? '
            'The application will move from Pending to Accepted.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(false),
              child:
                  const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(true),
              icon: const Icon(
                Icons
                    .check_circle_outline_rounded,
                size: 18,
              ),
              label:
                  const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {});

    HapticFeedback.mediumImpact();

    final updated =
        await _controller.acceptApplicant(
      jobId: widget.jobId,
      application: _application,
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
      _application = updated;
      _changed = true;
    });

    _showSnack(
      'Applicant accepted successfully.',
    );
  }

  Future<void> _reject() async {
    if (!_application.isPending || _acting) {
      return;
    }

    final reason =
        await _showRejectDialog();

    if (reason == null ||
        !mounted) {
      return;
    }

    setState(() {});

    HapticFeedback.mediumImpact();

    final updated =
        await _controller.rejectApplicant(
      jobId: widget.jobId,
      application: _application,
      reason: reason.trim().isEmpty
          ? null
          : reason.trim(),
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
      _application = updated;
      _changed = true;
    });

    _showSnack(
      'Applicant rejected.',
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Reject Applicant?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'You can add a rejection reason, or leave it empty.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Optional rejection reason...',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.cardBorder,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.cardBorder,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(null),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(controller.text),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
              ),
              child:
                  const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visual =
        _applicationVisual(
      _application.status,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue
                          .withOpacity(0.09),
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
                _topBar(),
                Expanded(
                  child: ListView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      28,
                    ),
                    children: [
                      _hero(visual),
                      const SizedBox(height: 14),
                      _applicationInfo(),
                      const SizedBox(height: 14),
                      _pilotSection(),
                      const SizedBox(height: 14),
                      _droneSection(),
                      if (_application
                          .coverMessage
                          .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _section(
                          title: 'Cover Message',
                          icon: Icons
                              .chat_bubble_outline_rounded,
                          child: Text(
                            _application.coverMessage,
                            style:
                                const TextStyle(
                              color:
                                  AppColors.text,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      if (_application
                          .rejectionReason
                          .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _section(
                          title:
                              'Rejection Reason',
                          icon: Icons
                              .info_outline_rounded,
                          child: Text(
                            _application
                                .rejectionReason,
                            style:
                                const TextStyle(
                              color:
                                  AppColors.text,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _application.isPending
              ? _bottomActions()
              : null,
    );
  }

  Widget _topBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        8,
        8,
        12,
        4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pop(
              _changed,
            ),
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 18,
            ),
          ),
          const Expanded(
            child: Text(
              'Applicant Details',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppColors.navy,
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _hero(_VisualPair visual) {
    final pilot =
        _application.pilotProfile;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF122A3A),
            Color(0xFF0D3B4A),
            Color(0xFF087E8F),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: visual.background,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _application.statusLabel,
                  style: TextStyle(
                    color:
                        visual.foreground,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${_application.id}',
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.65),
                  fontSize: 11.5,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Colors.white
                        .withOpacity(0.12),
                foregroundImage:
                    pilot?.profilePhoto
                                .trim()
                                .isNotEmpty ==
                            true
                        ? NetworkImage(
                            pilot!.profilePhoto,
                          )
                        : null,
                child: pilot?.profilePhoto
                            .trim()
                            .isNotEmpty ==
                        true
                    ? null
                    : Text(
                        _initial(),
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pilotName(),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pilotHeroSubtitle(),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.68),
                        fontSize: 11.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _applicationInfo() {
    return _section(
      title: 'Application',
      icon:
          Icons.assignment_outlined,
      child: Column(
        children: [
          _infoRow(
            'Job',
            '#${_application.jobPostingId}',
          ),
          _infoRow(
            'Application',
            '#${_application.id}',
          ),
          _infoRow(
            'Submitted',
            _formatDateTime(
              _application.createdAt,
            ),
          ),
          if (_application.decidedAt != null)
            _infoRow(
              'Decision',
              _formatDateTime(
                _application.decidedAt,
              ),
            ),
          if (_application.withdrawnAt != null)
            _infoRow(
              'Withdrawn',
              _formatDateTime(
                _application.withdrawnAt,
              ),
            ),
        ],
      ),
    );
  }

  Widget _pilotSection() {
    final pilot =
        _application.pilotProfile;

    if (pilot == null) {
      return _section(
        title: 'Pilot Profile',
        icon:
            Icons.person_outline_rounded,
        child: Text(
          'Pilot #${_application.pilotProfileId}',
          style:
              const TextStyle(
            color:
                AppColors.navy,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      );
    }

    return _section(
      title: 'Pilot Profile',
      icon:
          Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _infoRow(
            'Name',
            pilot.displayName,
          ),
          if (pilot.location.isNotEmpty)
            _infoRow(
              'Location',
              pilot.location,
            ),
          if (pilot.experienceLabel.isNotEmpty)
            _infoRow(
              'Experience',
              pilot.experienceLabel,
            ),
          if (pilot.nationality.isNotEmpty)
            _infoRow(
              'Nationality',
              pilot.nationality,
            ),
          if (pilot.languages.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Languages',
              style: TextStyle(
                color:
                    AppColors.grey,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.languages
                  .map(
                    (language) =>
                        _chip(language),
                  )
                  .toList(),
            ),
          ],
          if (pilot.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'About',
              style: TextStyle(
                color:
                    AppColors.grey,
                fontSize: 11.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pilot.bio,
              style:
                  const TextStyle(
                color:
                    AppColors.text,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
          if (pilot.previousCompany.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 12,
              ),
              child: _infoRow(
                'Previous',
                pilot.previousCompany,
              ),
            ),
        ],
      ),
    );
  }

  Widget _droneSection() {
    final drone =
        _application.drone;

    if (drone == null) {
      return _section(
        title: 'Committed Drone',
        icon:
            Icons.flight_outlined,
        child: Text(
          'Drone #${_application.droneId}',
          style:
              const TextStyle(
            color:
                AppColors.navy,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      );
    }

    return _section(
      title: 'Committed Drone',
      icon:
          Icons.flight_outlined,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.greenBg,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color:
                      AppColors.green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      drone.displayName,
                      style:
                          const TextStyle(
                        color:
                            AppColors.navy,
                        fontSize: 14.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (drone.manufactureYear !=
                        null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${drone.manufactureYear}',
                        style:
                            const TextStyle(
                          color:
                              AppColors.grey,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (drone.capabilities.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: drone.capabilities
                  .map(
                    (capability) =>
                        _chip(capability),
                  )
                  .toList(),
            ),
          ],
          if (drone.serialNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(
              'Serial',
              drone.serialNumber,
            ),
          ],
          if (drone.weightKg != null)
            _infoRow(
              'Weight',
              '${_cleanNumber(drone.weightKg!)} kg',
            ),
          if (drone.flightTimePerBatteryMinutes !=
              null)
            _infoRow(
              'Flight time',
              '${drone.flightTimePerBatteryMinutes} min/battery',
            ),
          if (drone.totalBatteries != null)
            _infoRow(
              'Batteries',
              '${drone.totalBatteries}',
            ),
        ],
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
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.blueBg,
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      AppColors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      AppColors.navy,
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight.w800,
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
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    AppColors.grey,
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    AppColors.navy,
                fontSize: 12.2,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              AppColors.blue,
          fontSize: 10.5,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          11,
          16,
          14,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  AppColors.cardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  OutlinedButton.icon(
                onPressed:
                    _acting
                        ? null
                        : _reject,
                style:
                    OutlinedButton
                        .styleFrom(
                  minimumSize:
                      const Size(
                    0,
                    52,
                  ),
                  foregroundColor:
                      AppColors.red,
                  side:
                      const BorderSide(
                    color:
                        AppColors.red,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                icon: _controller
                            .isRejectingApplicant
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              AppColors.red,
                        ),
                      )
                    : const Icon(
                        Icons
                            .close_rounded,
                        size: 18,
                      ),
                label:
                    const Text(
                  'Reject',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  FilledButton.icon(
                onPressed:
                    _acting
                        ? null
                        : _accept,
                style:
                    FilledButton
                        .styleFrom(
                  minimumSize:
                      const Size(
                    0,
                    52,
                  ),
                  backgroundColor:
                      AppColors.green,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                icon: _controller
                            .isAcceptingApplicant
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .check_rounded,
                        size: 18,
                      ),
                label:
                    const Text(
                  'Accept',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pilotName() {
    final pilot =
        _application.pilotProfile;

    if (pilot != null) {
      return pilot.displayName;
    }

    return 'Pilot #${_application.pilotProfileId}';
  }

  String _initial() {
    final name =
        _pilotName().trim();

    if (name.isEmpty) {
      return 'P';
    }

    return name[0].toUpperCase();
  }

  String _pilotHeroSubtitle() {
    final pilot =
        _application.pilotProfile;

    if (pilot == null) {
      return 'Pilot profile #${_application.pilotProfileId}';
    }

    final parts = <String>[];

    if (pilot.location.isNotEmpty) {
      parts.add(pilot.location);
    }

    if (pilot.experienceLabel.isNotEmpty) {
      parts.add(pilot.experienceLabel);
    }

    return parts.isEmpty
        ? 'Pilot profile #${pilot.id}'
        : parts.join(' · ');
  }

  String _formatDateTime(
    DateTime? value,
  ) {
    if (value == null) {
      return '—';
    }

    final local =
        value.toLocal();

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    final hour =
        local.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    return '${local.year}-$month-$day · $hour:$minute';
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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              isError
                  ? Colors.red.shade700
                  : AppColors.navy,
          content:
              Text(message),
        ),
      );
  }
}

class _VisualPair {
  final Color foreground;
  final Color background;

  const _VisualPair(
    this.foreground,
    this.background,
  );
}

_VisualPair _applicationVisual(
  String status,
) {
  switch (
      status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        AppColors.green,
        AppColors.greenBg,
      );

    case 'rejected':
      return _VisualPair(
        Colors.red.shade700,
        Colors.red.shade50,
      );

    case 'withdrawn':
      return _VisualPair(
        AppColors.grey,
        Colors.grey.shade100,
      );

    default:
      return const _VisualPair(
        AppColors.blue,
        AppColors.blueBg,
      );
  }
}
