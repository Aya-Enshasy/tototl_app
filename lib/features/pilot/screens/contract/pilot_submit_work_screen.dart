import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
 import '../../controllers/pilot_contract_controller.dart';
import '../../../company/models/contract_submission_model.dart';
import '../../services/pilot_contract_service.dart';

class PilotSubmitWorkScreen extends StatefulWidget {
  const PilotSubmitWorkScreen({
    super.key,
    required this.contractId,
    this.previousSubmission,
  });

  final int contractId;
  final ContractSubmissionModel? previousSubmission;

  @override
  State<PilotSubmitWorkScreen> createState() => _PilotSubmitWorkScreenState();
}

class _PilotSubmitWorkScreenState extends State<PilotSubmitWorkScreen> {
  static const int _maxFiles = 10;
  static const int _maxBytes = 20 * 1024 * 1024;

  late final PilotContractController _controller;
  final TextEditingController _notesController = TextEditingController();
  final List<PlatformFile> _files = [];

  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _controller = PilotContractController(PilotContractService(ApiClient()));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _busy => _controller.isSubmittingWork || _picking;

  Future<void> _pickFiles() async {
    if (_busy || _files.length >= _maxFiles) return;
    HapticFeedback.selectionClick();
    setState(() => _picking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
          'mp4',
          'mov',
        ],
      );
      if (result == null || !mounted) return;

      final accepted = <PlatformFile>[];
      for (final file in result.files) {
        if (_files.length + accepted.length >= _maxFiles) break;
        final path = file.path?.trim() ?? '';
        if (path.isEmpty) continue;
        final local = File(path);
        if (!await local.exists()) continue;
        final bytes = await local.length();
        if (bytes > _maxBytes) {
          if (mounted) {
            _snack('${file.name} is larger than 20 MB.', error: true);
          }
          continue;
        }
        final duplicate = _files.any((item) => item.path == path) ||
            accepted.any((item) => item.path == path);
        if (!duplicate) accepted.add(file);
      }

      if (!mounted) return;
      setState(() => _files.addAll(accepted));

      if (result.files.length > accepted.length && _files.length >= _maxFiles) {
        _snack('Maximum 10 files per submission.');
      }
    } on PlatformException {
      if (mounted) _snack('Unable to open the file picker.', error: true);
    } catch (_) {
      if (mounted) _snack('Unable to add these files.', error: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;

    final notes = _notesController.text.trim();
    if (notes.length > 2000) {
      _snack('Notes cannot exceed 2000 characters.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Submit completed work?',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _files.isEmpty
              ? 'Submit this work round with the current notes and no attachments? The company will receive it for review.'
              : 'Submit ${_files.length} attachment${_files.length == 1 ? '' : 's'} to the company for review?',
          style: const TextStyle(
            color: AppColors.grey,
            height: 1.5,
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Submit Work'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});

    final result = await _controller.submitWork(
      widget.contractId,
      notes: notes.isEmpty ? null : notes,
      filePaths: _files
          .map((file) => file.path?.trim() ?? '')
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() {});
      _snack(
        _controller.actionErrorMessage ?? 'Unable to submit work.',
        error: true,
      );
      return;
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final previous = widget.previousSubmission;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Work',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Deliverables & completion notes',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          children: [
            _hero(),
            if (previous?.isRevisionRequested == true) ...[
              const SizedBox(height: 12),
              _revisionCard(previous!),
            ],
            const SizedBox(height: 12),
            _section(
              title: 'Completion Notes',
              icon: Icons.notes_rounded,
              child: TextField(
                controller: _notesController,
                minLines: 5,
                maxLines: 9,
                maxLength: 2000,
                enabled: !_busy,
                decoration: _inputDecoration(
                  'Summarize what was completed, observations, coverage, or anything the company should know...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Deliverables',
              icon: Icons.attach_file_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Images, PDF reports, MP4 or MOV video • up to 10 files • 20 MB each',
                    style: TextStyle(
                      color: AppColors.grey.withOpacity(0.95),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy || _files.length >= _maxFiles
                        ? null
                        : _pickFiles,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: _picking
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.blue,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _files.isEmpty
                          ? 'Add Files'
                          : 'Add More (${_files.length}/$_maxFiles)',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._files.asMap().entries.map(
                      (entry) => _fileTile(entry.key, entry.value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: FilledButton.icon(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _controller.isSubmittingWork
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 19),
            label: Text(
              _controller.isSubmittingWork
                  ? 'Submitting Work...'
                  : 'Submit Work for Review',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071D39), Color(0xFF0A4055), Color(0xFF087E91)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.flight_rounded, color: Color(0xFF7BE4D8), size: 28),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work round ready for review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add completion notes and the evidence or deliverables agreed for this mission.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
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

  Widget _revisionCard(ContractSubmissionModel submission) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orangeBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.orange.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rate_review_outlined, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revision requested',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  submission.reviewNotes.trim().isEmpty
                      ? 'The company requested another work submission.'
                      : submission.reviewNotes,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
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

  Widget _fileTile(int index, PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(file.extension), color: AppColors.blue, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _sizeLabel(file.size),
                  style: const TextStyle(color: AppColors.grey, fontSize: 9.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: _busy ? null : () => setState(() => _files.removeAt(index)),
            icon: const Icon(Icons.close_rounded, color: AppColors.red, size: 19),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13.5,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.lightGrey, fontSize: 11),
      filled: true,
      fillColor: AppColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
      ),
    );
  }

  IconData _fileIcon(String? extension) {
    final ext = extension?.toLowerCase() ?? '';
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (ext == 'mp4' || ext == 'mov') return Icons.videocam_outlined;
    return Icons.image_outlined;
  }

  String _sizeLabel(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.red : AppColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(message),
        ),
      );
  }
}
