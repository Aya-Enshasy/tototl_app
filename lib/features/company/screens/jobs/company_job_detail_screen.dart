import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';
import '../../services/company_job_service.dart';

import 'edit_company_job_screen.dart';

class CompanyJobDetailScreen extends StatefulWidget {
  const CompanyJobDetailScreen({
    super.key,
    required this.jobId,
  });

  final int jobId;

  @override
  State<CompanyJobDetailScreen> createState() =>
      _CompanyJobDetailScreenState();
}

class _CompanyJobDetailScreenState
    extends State<CompanyJobDetailScreen> {
  late final CompanyJobController _controller;

  bool _loading = true;
  bool _actionLoading = false;
  String? _pageError;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _pageError = null;
      });
    }

    final detailSuccess =
        await _controller.loadJobDetails(widget.jobId);

    if (!mounted) return;

    if (!detailSuccess) {
      setState(() {
        _loading = false;
        _pageError =
            _controller.errorMessage ?? 'Unable to load job.';
      });
      return;
    }

    await _controller.loadApplicants(widget.jobId);

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final detailSuccess =
        await _controller.loadJobDetails(widget.jobId);

    if (detailSuccess) {
      await _controller.loadApplicants(widget.jobId);
    }

    if (!mounted) return;

    setState(() {
      _pageError = detailSuccess
          ? null
          : _controller.errorMessage;
    });
  }

  Future<void> _edit() async {
    final job = _controller.selectedJob;

    if (job == null || job.status.toLowerCase() != 'draft') {
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCompanyJobScreen(job: job),
      ),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _publish() async {
    final job = _controller.selectedJob;

    if (job == null || job.status.toLowerCase() != 'draft') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish Job?'),
        content: const Text(
          'Once published, pilots can see this job and submit applications. '
          'Editing and deleting are only available while the job is Draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);

    final published = await _controller.publishJob(job.id);

    if (!mounted) return;

    setState(() => _actionLoading = false);

    if (published == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to publish job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job published successfully.');
    await _refresh();
  }

  Future<void> _delete() async {
    final job = _controller.selectedJob;

    if (job == null || job.status.toLowerCase() != 'draft') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: Text(
          'Delete "${job.title}" permanently? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);

    final success = await _controller.deleteJob(job.id);

    if (!mounted) return;

    setState(() => _actionLoading = false);

    if (!success) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to delete job.',
        isError: true,
      );
      return;
    }

    _showSnack('Draft deleted.');

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _pageError != null
                ? _ErrorView(
                    message: _pageError!,
                    onRetry: _load,
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final job = _controller.selectedJob!;

    return Column(
      children: [
        _topBar(job),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              children: [
                _hero(job),
                const SizedBox(height: 14),
                _overview(job),
                const SizedBox(height: 14),
                _section(
                  title: 'Description',
                  child: Text(
                    job.description.isEmpty
                        ? 'No description provided.'
                        : job.description,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _requirements(job),
                if (job.attachments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _attachments(job),
                ],
                if (job.companyProfile != null) ...[
                  const SizedBox(height: 14),
                  _company(job.companyProfile!),
                ],
                const SizedBox(height: 22),
                _applicationsSection(job),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(CompanyJobPostingModel job) {
    final isDraft = job.status.toLowerCase() == 'draft';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
            ),
          ),
          const Expanded(
            child: Text(
              'Job Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isDraft)
            PopupMenuButton<String>(
              enabled: !_actionLoading,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.navy,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _edit();
                } else if (value == 'publish') {
                  _publish();
                } else if (value == 'delete') {
                  _delete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 19),
                      SizedBox(width: 10),
                      Text('Edit Draft'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'publish',
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded, size: 19),
                      SizedBox(width: 10),
                      Text('Publish Job'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Delete Draft',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _hero(CompanyJobPostingModel job) {
    final status = job.status.toLowerCase();
    final visual = _statusVisual(status);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _pretty(status),
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${job.id}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            job.title.isEmpty ? 'Untitled Job' : job.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (job.serviceCategory.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              _pretty(job.serviceCategory),
              style: const TextStyle(
                color: AppColors.lightGrey,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 17),
          Text(
            _payment(job),
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(CompanyJobPostingModel job) {
    return _section(
      title: 'Job Overview',
      child: Column(
        children: [
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _location(job),
          ),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Start',
            value: _formatDate(job.startDate),
          ),
          _infoRow(
            icon: Icons.event_available_outlined,
            label: 'End',
            value: _formatDate(job.endDate),
          ),
          _infoRow(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: _payment(job),
          ),
          if (job.droneSize.isNotEmpty)
            _infoRow(
              icon: Icons.flight_outlined,
              label: 'Drone Size',
              value: _pretty(job.droneSize),
            ),
          if (job.requiredExperience.isNotEmpty)
            _infoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Experience',
              value: job.requiredExperience,
            ),
          if (job.publishedAt != null)
            _infoRow(
              icon: Icons.public_rounded,
              label: 'Published',
              value: _formatDateTime(job.publishedAt),
            ),
          if (job.createdAt != null)
            _infoRow(
              icon: Icons.schedule_rounded,
              label: 'Created',
              value: _formatDateTime(job.createdAt),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _requirements(CompanyJobPostingModel job) {
    final hasAnything =
        job.requiredCapabilities.isNotEmpty ||
            job.requiredCertifications.isNotEmpty ||
            job.requiredExperience.isNotEmpty ||
            job.droneSize.isNotEmpty ||
            job.trainingSafetyRequired ||
            job.ndaRequired ||
            job.requirementsNotes.isNotEmpty;

    return _section(
      title: 'Requirements',
      child: hasAnything
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job.requiredCapabilities.isNotEmpty) ...[
                  const _SubLabel('Required Capabilities'),
                  const SizedBox(height: 8),
                  _chipWrap(
                    job.requiredCapabilities,
                    AppColors.greenBg,
                    AppColors.green,
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.requiredCertifications.isNotEmpty) ...[
                  const _SubLabel('Required Certifications'),
                  const SizedBox(height: 8),
                  _chipWrap(
                    job.requiredCertifications,
                    AppColors.blueBg,
                    AppColors.blue,
                  ),
                  const SizedBox(height: 16),
                ],
                if (job.trainingSafetyRequired)
                  _requirementLine(
                    Icons.health_and_safety_outlined,
                    'Safety training required',
                  ),
                if (job.ndaRequired)
                  _requirementLine(
                    Icons.lock_outline_rounded,
                    'NDA required',
                  ),
                if (job.requirementsNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SubLabel('Other Requirements'),
                  const SizedBox(height: 6),
                  Text(
                    job.requirementsNotes,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            )
          : const Text(
              'No additional requirements.',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
    );
  }

  Widget _attachments(CompanyJobPostingModel job) {
    return _section(
      title: 'Attachments (${job.attachments.length})',
      child: Column(
        children: job.attachments.map((attachment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    attachment.isImage
                        ? Icons.image_outlined
                        : Icons.insert_drive_file_outlined,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.name.isEmpty
                            ? 'Attachment'
                            : attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _fileSize(attachment.size),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _company(CompanyJobCompanyProfileModel company) {
    return _section(
      title: 'Company',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company.companyName.isEmpty
                ? 'Company #${company.id}'
                : company.companyName,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (company.industryType.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              company.industryType,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12.5,
              ),
            ),
          ],
          if (company.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    company.address,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _applicationsSection(CompanyJobPostingModel job) {
    final applicants = _controller.applicants;
    final error = _controller.applicantsErrorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Applications',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${applicants.length}',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (error != null)
          _applicationsError(error)
        else if (applicants.isEmpty)
          const _EmptyApplications()
        else
          ...applicants.map(
            (application) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ApplicantCard(
                application: application,
              ),
            ),
          ),
      ],
    );
  }

  Widget _applicationsError(String message) {
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
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _controller.loadApplicants(widget.jobId);

              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 17,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipWrap(
    List<String> items,
    Color background,
    Color foreground,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _location(CompanyJobPostingModel job) {
    final parts = <String>[
      if (job.city.isNotEmpty) job.city,
      if (job.state.isNotEmpty) job.state,
      if (job.country.isNotEmpty) job.country,
    ];

    if (parts.isEmpty && job.region.isNotEmpty) {
      return job.region;
    }

    if (job.region.isNotEmpty) {
      parts.insert(0, job.region);
    }

    return parts.isEmpty
        ? 'Location not specified'
        : parts.join(', ');
  }

  String _payment(CompanyJobPostingModel job) {
    if (job.paymentType.toLowerCase() == 'negotiable') {
      return 'Negotiable';
    }

    final type = _pretty(job.paymentType);
    final min = _money(job.paymentMin);
    final max = _money(job.paymentMax);

    if (job.paymentMin == null && job.paymentMax == null) {
      return type.isEmpty ? 'Payment not specified' : type;
    }

    if (job.paymentMax == null) {
      return type.isEmpty ? '\$$min' : '$type · \$$min';
    }

    return type.isEmpty
        ? '\$$min - \$$max'
        : '$type · \$$min - \$$max';
  }

  String _money(double? value) {
    if (value == null) return '';

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} · $hour:$minute';
  }

  String _fileSize(int bytes) {
    if (bytes <= 0) return 'Size unavailable';

    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;

    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  String _pretty(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '';

    return clean
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
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
          content: Text(message),
        ),
      );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.application,
  });

  final CompanyJobApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final pilot = application.pilotProfile;
    final drone = application.drone;

    final pilotName = pilot?.name.trim().isNotEmpty == true
        ? pilot!.name
        : 'Pilot #${application.pilotProfileId}';

    final initial = pilotName.trim().isEmpty
        ? 'P'
        : pilotName.trim()[0].toUpperCase();

    final visual = _applicationVisual(application.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.blueBg,
                foregroundImage:
                    pilot?.profilePhoto.trim().isNotEmpty == true
                        ? NetworkImage(pilot!.profilePhoto)
                        : null,
                child: pilot?.profilePhoto.trim().isNotEmpty == true
                    ? null
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _pilotSubtitle(application),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.8,
                      ),
                    ),
                  ],
                ),
              ),
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
                  _prettyGlobal(application.status),
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (application.coverMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                application.coverMessage,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.flight_outlined,
                size: 15,
                color: AppColors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  drone?.displayName ?? 'Drone #${application.droneId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.8,
                  ),
                ),
              ),
              if (application.createdAt != null)
                Text(
                  _smallDate(application.createdAt!),
                  style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 10.8,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _pilotSubtitle(CompanyJobApplicationModel application) {
    final pilot = application.pilotProfile;

    final parts = <String>[];

    if (pilot != null && pilot.location.isNotEmpty) {
      parts.add(pilot.location);
    }

    if (pilot?.experienceYears != null) {
      parts.add('${pilot!.experienceYears} yrs exp');
    }

    if (parts.isEmpty) {
      return 'Application #${application.id}';
    }

    return parts.join(' · ');
  }

  String _smallDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
        fontSize: 11.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: AppColors.lightGrey,
            size: 34,
          ),
          SizedBox(height: 9),
          Text(
            'No applications yet',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilot applications for this job will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.grey,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
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

_VisualPair _statusVisual(String status) {
  switch (status.toLowerCase()) {
    case 'published':
      return const _VisualPair(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'draft':
      return const _VisualPair(
        AppColors.orange,
        AppColors.orangeBg,
      );
    case 'cancelled':
      return _VisualPair(
        Colors.red.shade700,
        Colors.red.shade50,
      );
    case 'closed':
      return _VisualPair(
        AppColors.grey,
        Colors.grey.shade100,
      );
    default:
      return const _VisualPair(
        AppColors.grey,
        AppColors.blueBg,
      );
  }
}

_VisualPair _applicationVisual(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'pending':
      return const _VisualPair(
        AppColors.blue,
        AppColors.blueBg,
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
        AppColors.grey,
        AppColors.blueBg,
      );
  }
}

String _prettyGlobal(String value) {
  final clean = value.trim();

  if (clean.isEmpty) return 'Unknown';

  return clean
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
