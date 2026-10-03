import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/contract_submission_model.dart';
import '../../services/company_contract_service.dart';
import '../applications/company_document_viewer_screen.dart';

class CompanySubmissionReviewScreen extends StatefulWidget {
  const CompanySubmissionReviewScreen({
    super.key,
    required this.contractId,
    required this.submission,
  });

  final int contractId;
  final ContractSubmissionModel submission;

  @override
  State<CompanySubmissionReviewScreen> createState() =>
      _CompanySubmissionReviewScreenState();
}

class _CompanySubmissionReviewScreenState
    extends State<CompanySubmissionReviewScreen> {
  late final CompanyContractController _controller;
  late ContractSubmissionModel _submission;
  bool _loading = false;
  String? _openingAttachmentKey;

  @override
  void initState() {
    super.initState();
    _controller = CompanyContractController(CompanyContractService(ApiClient()));
    _submission = widget.submission;
    _loadFresh();
  }

  bool get _busy => _loading || _controller.isReviewingSubmission;

  Future<void> _loadFresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final fresh = await _controller.service.getSubmission(
        widget.contractId,
        widget.submission.id,
      );
      if (!mounted) return;
      setState(() => _submission = fresh);
    } catch (_) {
      // Keep the submission already supplied by the contract detail screen.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    if (_busy || !_submission.isSubmitted) return;
    final notes = await _reviewDialog(
      title: 'Approve & Complete',
      hint: 'Optional review note...',
      noteRequired: false,
      destructive: false,
    );
    if (notes == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});
    final result = await _controller.approveSubmission(
      widget.contractId,
      _submission.id,
      reviewNotes: notes.trim().isEmpty ? null : notes.trim(),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {});
      _snack(_controller.actionErrorMessage ?? 'Unable to approve submission.', error: true);
      return;
    }
    setState(() => _submission = result.submission);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _requestRevision() async {
    if (_busy || !_submission.isSubmitted) return;
    final notes = await _reviewDialog(
      title: 'Request Revision',
      hint: 'Explain exactly what the pilot must fix or add...',
      noteRequired: true,
      destructive: true,
    );
    if (notes == null || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {});
    final result = await _controller.requestRevision(
      widget.contractId,
      _submission.id,
      reviewNotes: notes.trim(),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {});
      _snack(_controller.actionErrorMessage ?? 'Unable to request revision.', error: true);
      return;
    }
    setState(() => _submission = result.submission);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<String?> _reviewDialog({
    required String title,
    required String hint,
    required bool noteRequired,
    required bool destructive,
  }) async {
    String draft = '';
    String? validation;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noteRequired
                      ? 'Revision instructions are required so the pilot knows exactly what to change.'
                      : 'Approval completes the contract. You may add an optional review note.',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLength: 2000,
                  minLines: 4,
                  maxLines: 7,
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
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                  destructive ? AppColors.orange : AppColors.green,
                ),
                onPressed: () {
                  final value = draft.trim();
                  if (noteRequired && value.isEmpty) {
                    setLocalState(
                          () => validation = 'Revision instructions are required.',
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: Text(
                  noteRequired
                      ? 'Send Revision Request'
                      : 'Approve & Complete',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submission = _submission;
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
              'Review Submission',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Pilot delivery & review decision',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
                ),
              ),
            )
          else
            IconButton(onPressed: _busy ? null : _loadFresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          _hero(submission),
          const SizedBox(height: 12),
          _section(
            title: 'Pilot Notes',
            icon: Icons.notes_rounded,
            child: Text(
              submission.notes.trim().isEmpty
                  ? 'No completion notes were provided.'
                  : submission.notes,
              style: TextStyle(
                color: submission.notes.trim().isEmpty ? AppColors.grey : AppColors.text,
                fontSize: 11.5,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Attachments (${submission.files.length})',
            icon: Icons.attach_file_rounded,
            child: submission.files.isEmpty
                ? const Text(
              'No attachments were included in this submission.',
              style: TextStyle(color: AppColors.grey, fontSize: 11),
            )
                : Column(
              children: submission.files
                  .map((file) => _attachmentTile(file))
                  .toList(growable: false),
            ),
          ),
          if (submission.reviewNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              title: 'Review Notes',
              icon: Icons.rate_review_outlined,
              child: Text(
                submission.reviewNotes,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: submission.isSubmitted
          ? SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _requestRevision,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    foregroundColor: AppColors.orange,
                    side: BorderSide(color: AppColors.orange.withOpacity(0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Revision', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _approve,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _controller.isReviewingSubmission
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Approve & Complete', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Widget _hero(ContractSubmissionModel submission) {
    final isSubmitted = submission.isSubmitted;
    final isRevision = submission.isRevisionRequested;
    final accent = isSubmitted
        ? AppColors.blue
        : isRevision
        ? AppColors.orange
        : AppColors.green;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  submission.statusLabel,
                  style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              Text('#${submission.id}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Work Submission',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            'Submitted ${submission.submittedLabel}',
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  bool _attachmentIsImage(
      ContractSubmissionFileModel file,
      ) {
    final source =
    '${file.displayName} ${file.url}'
        .toLowerCase();

    return source.contains('.png') ||
        source.contains('.jpg') ||
        source.contains('.jpeg') ||
        source.contains('.webp');
  }

  Uint8List _attachmentBytes(dynamic raw) {
    if (raw is Uint8List) return raw;

    if (raw is List<int>) {
      return Uint8List.fromList(raw);
    }

    if (raw is List) {
      try {
        return Uint8List.fromList(
          raw.map((value) => value as int).toList(),
        );
      } catch (_) {
        return Uint8List(0);
      }
    }

    return Uint8List(0);
  }

  String _attachmentExtension(String mime) {
    switch (mime.trim().toLowerCase()) {
      case 'application/pdf':
        return 'pdf';
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      case 'video/mp4':
        return 'mp4';
      default:
        return '';
    }
  }

  String _attachmentHeaderName(
      String disposition,
      ) {
    final match = RegExp(
      "filename\\s*=\\s*\\\"?([^\\\";]+)\\\"?",
      caseSensitive: false,
    ).firstMatch(disposition);

    return match?.group(1)?.trim() ?? '';
  }

  Future<
      ({
      String path,
      String name,
      String mime,
      })> _downloadAttachment(
      ContractSubmissionFileModel file,
      ) async {
    final url = file.url.trim();

    final token =
    await TokenStorage.getAccessToken();

    if (url.isEmpty) {
      throw StateError(
        'Attachment URL is missing.',
      );
    }

    if (token == null ||
        token.trim().isEmpty) {
      throw StateError(
        'Authentication token not found.',
      );
    }

    final response =
    await Dio().get<dynamic>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {
          'Accept': '*/*',
          'Authorization':
          'Bearer ${token.trim()}',
        },
      ),
    );

    final bytes =
    _attachmentBytes(
      response.data,
    );

    if (bytes.isEmpty) {
      throw StateError(
        'The downloaded attachment is empty.',
      );
    }

    final mime =
    (response.headers.value(
      Headers.contentTypeHeader,
    ) ??
        '')
        .split(';')
        .first
        .trim();

    var name =
    _attachmentHeaderName(
      response.headers.value(
        'content-disposition',
      ) ??
          '',
    );

    if (name.isEmpty) {
      name = file.displayName.trim();
    }

    if (name.isEmpty) {
      name = 'mission_file';
    }

    name = name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (!RegExp(
      r'\.[a-z0-9]{1,8}$',
    ).hasMatch(name.toLowerCase())) {
      final ext =
      _attachmentExtension(
        mime,
      );

      if (ext.isNotEmpty) {
        name = '$name.$ext';
      }
    }

    final directory =
    Directory(
      '${Directory.systemTemp.path}'
          '${Platform.pathSeparator}'
          'tototl_submission_media',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final idMatch = RegExp(
      r'/media/(\d+)/download',
      caseSensitive: false,
    ).firstMatch(url);

    final prefix =
        idMatch?.group(1) ??
            url.hashCode.abs().toString();

    final local =
    File(
      '${directory.path}'
          '${Platform.pathSeparator}'
          '${prefix}_$name',
    );

    await local.writeAsBytes(
      bytes,
      flush: true,
    );

    return (
    path: local.path,
    name: name,
    mime: mime,
    );
  }

  bool _attachmentPreviewable(
      String name,
      String mime,
      ) {
    final m = mime.toLowerCase();
    final n = name.toLowerCase();

    return m == 'application/pdf' ||
        m.startsWith('image/') ||
        n.endsWith('.pdf') ||
        n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.webp');
  }

  Future<void> _openAttachment(
      ContractSubmissionFileModel file,
      ) async {
    final key = file.url.trim();

    if (key.isEmpty) {
      _snack(
        'This attachment does not have an available URL.',
        error: true,
      );
      return;
    }

    if (_openingAttachmentKey != null) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _openingAttachmentKey = key;
    });

    try {
      final downloaded =
      await _downloadAttachment(
        file,
      );

      if (!mounted) return;

      if (_attachmentPreviewable(
        downloaded.name,
        downloaded.mime,
      )) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CompanyDocumentViewerScreen(
                  filePath: downloaded.path,
                  fileName: downloaded.name,
                  mimeType: downloaded.mime,
                ),
          ),
        );
      } else {
        final result =
        await OpenFilex.open(
          downloaded.path,
        );

        if (!mounted) return;

        if (result.type != ResultType.done) {
          _snack(
            result.message.trim().isNotEmpty
                ? result.message
                : 'No application could open this attachment.',
            error: true,
          );
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;

      final status = e.response?.statusCode;

      _snack(
        status == 401 || status == 403
            ? 'The server rejected access to this protected attachment.'
            : 'Unable to download this attachment.',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _snack(
        e.toString().replaceFirst(
          'Bad state: ',
          '',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingAttachmentKey = null;
        });
      }
    }
  }

  Widget _attachmentTile(
      ContractSubmissionFileModel file,
      ) {
    final hasUrl =
        file.url.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap:
          hasUrl ? () => _openAttachment(file) : null,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding:
            const EdgeInsets.fromLTRB(
              11,
              9,
              9,
              9,
            ),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _attachmentIsImage(file)
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
                  color: AppColors.blue,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.displayName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 10.8,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                      if (file.sizeLabel
                          .isNotEmpty)
                        Text(
                          file.sizeLabel,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                _openingAttachmentKey == file.url.trim()
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: AppColors.blue,
                  ),
                )
                    : Icon(
                  hasUrl
                      ? Icons.open_in_new_rounded
                      : Icons.link_off_rounded,
                  color: hasUrl
                      ? AppColors.blue
                      : AppColors.lightGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required IconData icon, required Widget child}) {
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
                decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: AppColors.navy, fontSize: 13.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
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
